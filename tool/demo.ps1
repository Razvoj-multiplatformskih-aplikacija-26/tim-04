param(
  [string]$Base = 'http://localhost:8080',
  [string]$Password = 'utociste-demo'
)

$ErrorActionPreference = 'Stop'

function Request-Id([int]$Number) { '00000000-0000-4000-8000-' + $Number.ToString().PadLeft(12, '0') }

function Send([string]$Method, [string]$Path, [string]$Token, $Body) {
  $headers = @{}
  if ($Token) { $headers.Authorization = "Bearer $Token" }
  $request = @{ Method = $Method; Uri = "$Base$Path"; Headers = $headers; UseBasicParsing = $true }
  if ($Body) {
    $request.ContentType = 'application/json; charset=utf-8'
    $request.Body = [Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Compress))
  }
  try {
    $response = Invoke-WebRequest @request
    [pscustomobject]@{ Status = [int]$response.StatusCode; Body = $response.Content }
  } catch [System.Net.WebException] {
    [pscustomobject]@{ Status = [int]$_.Exception.Response.StatusCode; Body = $_.ErrorDetails.Message }
  }
}

function Expect([string]$Label, $Answer, [int]$Status, [string]$Code) {
  $actual = if ($Code) { ($Answer.Body | ConvertFrom-Json).code } else { '' }
  $ok = $Answer.Status -eq $Status -and $actual -eq $Code
  $mark = if ($ok) { 'OK  ' } else { 'FAIL' }
  Write-Host ("[{0}] {1}: {2} {3}" -f $mark, $Label, $Answer.Status, $actual)
}

function Log-In([string]$Login) {
  $answer = Send 'POST' '/api/v1/sessions' $null @{ username = $Login; password = $Password }
  ($answer.Body | ConvertFrom-Json).token
}

$ana = Log-In 'udomitelj1'
$marko = Log-In 'udomitelj2'
$coordinator = Log-In 'koordinator1'
$motivation = 'Imamo veliko dvorište i mnogo slobodnog vremena.'

Write-Host "`n1. Pravila važe i mimo aplikacije"
Expect 'prekratka motivacija' (Send 'POST' '/api/v1/adoption-requests' $ana @{ animalId = 'a-03'; motivation = 'Kratko.' }) 422 'motivation-too-short'
Expect 'prekratko ime životinje' (Send 'POST' '/api/v1/animals' $coordinator @{ name = 'R'; species = 'dog'; birthDate = '2024-01-01'; description = 'Pronađen.'; enclosureId = 'P-2' }) 422 'name-too-short'
Expect 'drugi aktivni zahtev' (Send 'POST' '/api/v1/adoption-requests' $marko @{ animalId = 'a-03'; motivation = $motivation }) 201 ''
Expect 'treći aktivni zahtev' (Send 'POST' '/api/v1/adoption-requests' $marko @{ animalId = 'a-04'; motivation = $motivation }) 409 'too-many-active-requests'

Write-Host "`n2. Tri istovremena odobrenja za Rexa (r-01, r-02, r-03)"
$urls = foreach ($n in 1..3) { "$Base/api/v1/adoption-requests/$(Request-Id $n)/approval" }
$codes = & curl.exe -s -Z -X POST -H "Authorization: Bearer $coordinator" -o NUL -o NUL -o NUL -w '%{http_code}\n' @urls
Write-Host ("odgovori: {0}" -f ($codes -join ', '))
$approved = @($codes | Where-Object { $_ -eq '200' }).Count
$refused = @($codes | Where-Object { $_ -eq '409' }).Count
$mark = if ($approved -eq 1 -and $refused -eq 2) { 'OK  ' } else { 'FAIL' }
Write-Host "[$mark] tačno jedno odobrenje, ostala dva 409"

Write-Host "`n3. Akcije backoffice-a sa tokenom udomitelja"
Expect 'odobravanje svog zahteva' (Send 'POST' "/api/v1/adoption-requests/$(Request-Id 4)/approval" $ana $null) 403 'not-allowed'
Expect 'prijem životinje' (Send 'POST' '/api/v1/animals' $ana @{ name = 'Novi'; species = 'dog'; birthDate = '2024-01-01'; description = 'Pronađen.'; enclosureId = 'P-2' }) 403 'not-allowed'
Expect 'početak karantina' (Send 'POST' '/api/v1/animals/a-05/quarantine' $ana @{ until = '2026-12-01T00:00:00Z' }) 403 'not-allowed'

Write-Host "`n4. Tuđ zahtev ne postoji"
Expect 'povlačenje Miličinog zahteva' (Send 'POST' "/api/v1/adoption-requests/$(Request-Id 5)/withdrawal" $ana $null) 404 'not-found'

Write-Host "`n5. Bez prijave i sa lošim tokenom"
Expect 'katalog bez prijave' (Send 'GET' '/api/v1/animals' $null $null) 200 ''
Expect 'zahtevi bez prijave' (Send 'GET' '/api/v1/adoption-requests' $null $null) 401 'sign-in-required'
Expect 'izmenjen token' (Send 'GET' '/api/v1/adoption-requests' "$($ana)x" $null) 401 'session-expired'