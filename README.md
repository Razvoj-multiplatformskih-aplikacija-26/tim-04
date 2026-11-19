# Utočište za životinje

Projekat iz predmeta *Razvoj multiplatformskih aplikacija*

## Članovi tima

| Ime i prezime | Broj indeksa | GitHub |
|---|---|---|
| Zorana Mrkić | 124/24 SI | zoranamrkic05 |
| Ana Jocić | 110/24 SI | jocicana |

## Opis sistema

Utočište prima napuštene životinje različitih vrsta (psi, krave, koze, konji), brine o njima i traži im novi dom. Budući vlasnici podnose zahteve za udomljavanje, volonteri i veterinari vode dnevnu evidenciju o životinjama, a koordinator odobrava zahteve i prati kapacitet. Životinje koje zbog zdravlja, starosti ili ponašanja ostaju u utočištu trajno otvaraju se za virtuelno kumstvo — mesečnu pomoć u izdržavanju, u kojoj može učestvovati više kumova.

Glavni pojam sistema je **životinja**; zahtevi za udomljavanje i kumstva vezuju se za njen zapis.

## Ispunjenost zahteva

**1. Uloge.** Sistem ima četiri uloge sa različitim ovlašćenjima: posetilac (javni katalog), korisnik (podnosi zahtev i preuzima kumstvo), volonter i veterinar (vode evidenciju nege i zdravlja) i koordinator (odobrava zahteve, upravlja kapacitetom i statusima).

**2. Stanja.** Životinja prolazi kroz stanja: primljena, u karantinu, spremna za udomljavanje, rezervisana i udomljena, uz sporedna stanja trajni štićenik i vraćena.

**3. Pravila.** Korisnik može imati najviše dva aktivna zahteva, a zahtev se povlači samo do odobrenja. O zaključavanju životinje odlučuje server: kada prvi zahtev bude odobren, životinja prelazi u stanje rezervisana i svi ostali zahtevi za nju automatski se odbijaju — a pošto pravo odobravanja imaju koordinator i stariji volonter, dve osobe mogu istovremeno odlučivati o istoj životinji.

**4. Rad bez mreže.** Volonter unosi dnevnu evidenciju nege (hranjenje, šetnja, terapija, fotografija) u boksovima i ispustima gde često nema signala, a zapisi se šalju serveru pri povratku mreže; korisnik bez mreže može povući sopstveni zahtev ili otkazati kumstvo.

**5. Posao za osoblje.** Koordinator radi sa presekom svih zapisa — tabla popunjenosti boksova, kalendar vakcinacija i terapija za sve životinje, uporedni pregled konkurentskih zahteva po životinji i pregled kumstava — što zahteva veći ekran.

**6. Javni sadržaj.** Bez prijave su dostupni katalog životinja spremnih za udomljavanje sa zasebnom stranicom po životinji, lista životinja koje traže kuma, uslovi udomljavanja i radno vreme; stranica pojedinačne životinje je upravo ono što ljudi traže preko pretraživača.

## Pokretanje

Potrebni su Docker Desktop i Flutter 3.47.6.

### Baza i server

Iz korena repozitorijuma (PowerShell):

```powershell
copy .env.example .env
docker compose up -d
```

`compose.yaml` podiže dva servisa:

| Servis | Šta radi | Adresa |
| --- | --- | --- |
| `db` | PostgreSQL 17; pri prvom pokretanju prazne baze sam učitava šemu iz `apps/server/db/schema.sql` | `localhost:5433` |
| `server` | server u Dartu na Relic-u, slika iz `apps/server/Dockerfile` | http://localhost:8080 |

Lozinka baze, `DEMO_PASSWORD`, `JWT_SECRET` i portovi su u `.env`, koji nije u git-u. Ako je port zauzet, promenite ga u `.env`: `POSTGRES_PORT` (i isti port u `DATABASE_URL`), `SERVER_PORT` (aplikacije tada pokrenite sa `--dart-define=SERVER_URL=http://localhost:<port>`) ili `ADMINER_PORT`. Kada je baza prazna, server upisuje početne podatke.

Provera: `curl.exe localhost:8080/health` (odgovor `ok`).

| Komanda | Šta radi |
| --- | --- |
| `docker compose logs server` | ispis servera |
| `docker compose up -d --build server` | nova slika servera posle izmene u `apps/server` ili u paketima |
| `docker compose down` | gasi sistem, podaci ostaju |
| `docker compose down -v` | gasi sistem i briše bazu; sledeći `up -d` ponovo učitava šemu i početne podatke |

Baza u pregledaču: `docker compose --profile tools up -d adminer`, pa http://127.0.0.1:8082. SQL iz terminala: `docker compose exec db psql -U utociste -d utociste`.

Server bez kontejnera, za debugger i brži restart:

```powershell
docker compose stop server
dart run apps/server/bin/server.dart
```

Server se zaustavlja sa Ctrl+C.

### Aplikacije

Prvo, u korenu repozitorijuma:

```powershell
flutter pub get
```

Aplikacije rade nad serverom. Android emulator ga nalazi na `10.0.2.2:8080`, a telefon na mreži uz `flutter run --dart-define=SERVER_URL=http://<IP računara>:8080`. Pregledač sme da zove server samo sa adrese iz `CORS_ORIGINS` u `.env`, pa backoffice u pregledaču radi na fiksnom portu 8081.

Mobilna aplikacija (Android emulator ili telefon):

```powershell
cd apps/mobile
flutter run
```

Backoffice (Windows ili pregledač):

```powershell
cd apps/backoffice
flutter run -d windows
```

```powershell
cd apps/backoffice
flutter run -d chrome --web-port 8081
```

Katalog životinja i stranica pojedinačne životinje dostupni su bez prijave; prijava se traži za slanje zahteva, „Moji zahtevi“ i sav rad osoblja.

### Demo nalozi

Lozinka za sve naloge je vrednost `DEMO_PASSWORD` iz `.env`.

| Nalog | Uloga | Aplikacija |
| --- | --- | --- |
| `udomitelj1`, `udomitelj2` | udomitelj | mobilna |
| `volonter1` | volonter | backoffice |
| `stariji1` | stariji volonter | backoffice |
| `veterinar1` | veterinar | backoffice |
| `koordinator1` | koordinator | backoffice |

### Testovi

Testovi paketa i aplikacija, u folderu svakog od njih (`packages/*`, `apps/mobile`, `apps/backoffice`):

```powershell
flutter test
```

Testovi servera traže pokrenutu bazu (`docker compose up -d db`) i rade nad posebnim test bazama `utociste_test_*`, pa ne diraju podatke iz razvoja:

```powershell
cd apps/server
dart test
```

## Odluke za KT2

### Pravila

| Pitanje | Odluka | Odbačeno i zašto |
| --- | --- | --- |
| Vrsta pravila | izbor jednog od više zahteva: prvi odobren zahtev rezerviše životinju, a ostali zahtevi na čekanju za nju se odbijaju; odlučuju koordinator i stariji volonter, pa dvoje može odlučivati istovremeno | „preklapanje u vremenu“ i „prag glasova“ ne opisuju našu temu |
| Ko konačno garantuje | baza, u jednoj transakciji: uslovni `UPDATE animals ... WHERE status = 'ready-for-adoption'` (0 redova znači da je neko već odobrio), pa promena svih zahteva za tu životinju; delimični jedinstveni indeksi dozvoljavaju najviše jedan odobren zahtev po životinji | provera u use case-u ili u kodu servera: dva istovremena poziva prođu proveru pre upisa, pa bi životinja bila odobrena dvaput |
| Šta vidi onaj ko je zakasnio | 409 sa kodom `invalid-request-transition` ili `animal-not-adoptable`, poruka i ponovo učitana lista, na kojoj se vidi da je drugi zahtev odobren | tiho prepisivanje (pobeđuje poslednji): životinja bi bila rezervisana za dva zahteva |
| Najviše 2 aktivna zahteva po korisniku | u transakciji `SELECT ... FROM users WHERE id = @user FOR UPDATE`, pa brojanje i upis; duplikat za istu životinju sprečava delimični jedinstveni indeks, a greška `23505` postaje 409 | samo `count(*)`: ne zaključava ništa, pa dva poziva sa dva uređaja vide isti broj i oba upišu |

### Ugovor

| Pitanje | Odluka | Odbačeno i zašto |
| --- | --- | --- |
| Šta vidi koja uloga | udomitelj i posetilac vide javne podatke životinje i samo svoje zahteve; osoblje vidi sve; tuđ zahtev je 404 | jedan odgovor za sve i sakrivanje u klijentu: podaci bi ipak stigli preko mreže |
| Vreme | trenutak u UTC-u, ISO 8601 (`2026-11-08T10:00:00Z`); datum rođenja je datum (`2023-04-15`) | lokalno vreme bez zone: telefon i server ga čitaju u različitim zonama |
| Stanja | objekat sa poljem `kind` i poljima tog stanja, npr. `{"kind": "in-quarantine", "since": ..., "until": ...}`; stanja zahteva kao string | broj (`status: 2`): nečitljivo i lomi se pri promeni redosleda |
| Greške | RFC 9457 (`application/problem+json`) sa kodom pravila i granicama; klijent od koda pravi istu domensku grešku kao pri proveri na uređaju | samo tekst poruke: klijent ne bi znao koje pravilo je prekršeno |
| Deo velike liste | filter na serveru (`?status=...&species=...`), bez straničenja, jer utočište ima desetine životinja | straničenje kursorom: više posla bez koristi za ovu količinu podataka |

### Klijenti

| Pitanje | Odluka | Odbačeno i zašto |
| --- | --- | --- |
| Kako klijent saznaje za tuđu promenu | osvežavanje: povlačenje nadole u mobilnoj, dugme u backoffice-u; ponovno učitavanje posle svake akcije i posle odbijenog poziva | WebSocket ili SSE: dovoljno je da se promena vidi posle osvežavanja, a push traži dodatni server i stanje veze |
| Šta pregledač ne dozvoljava | poziv sa druge adrese rešava CORS na serveru (`CORS_ORIGINS`, backoffice na fiksnom portu 8081); nema `dart:io`, pa `api_client` uslovnim importom bira `BrowserClient`; nema bezbednog skladišta, pa je sesija u HttpOnly kolačiću | `Access-Control-Allow-Origin: *`: ne radi sa kolačićima i dozvoljava bilo kom sajtu da zove server |

### Korisnici

| Pitanje | Odluka | Odbačeno i zašto |
| --- | --- | --- |
| Šta je dostupno bez prijave | katalog i stranica životinje; prijava se traži tek za slanje zahteva i „Moji zahtevi“ | prijava pri pokretanju: posetilac ne bi video katalog |
| Prijava | korisničko ime i lozinka; lozinke su heširane Argon2id-om; pogrešna lozinka i nepostojeći nalog daju isti odgovor | čuvanje lozinke u čistom tekstu ili brzim hešom: krađa baze otkriva lozinke |
| Sesija | JWT (HS256) sa korisnikom, ulogom i istekom; mobilna i Windows ga šalju u zaglavlju `Authorization: Bearer`, a pregledač ga dobija samo u HttpOnly kolačiću; istekla ili izmenjena sesija je 401 `session-expired`, a aplikacija vraća korisnika na prijavu | token u `localStorage` pregledača: dostupan svakom skriptu na stranici |
| Ko sme da menja tuđi zapis | udomitelj povlači samo svoj zahtev i samo dok je na čekanju; koordinator i stariji volonter odlučuju o zahtevima na čekanju; prijem i promena stanja životinje: koordinator; kraj karantina: koordinator ili veterinar; server proverava svaku akciju (403 `not-allowed`) | provera samo u aplikaciji: poziv mimo aplikacije bi prošao |

### Ostalo

| Pitanje | Odluka | Odbačeno i zašto |
| --- | --- | --- |
| Baza | PostgreSQL 17 u Docker-u: transakcije, zaključavanje redova, delimični jedinstveni indeksi | SQLite: zaključava celu bazu pri upisu i nema poseban servis; MongoDB: transakcija nad više dokumenata je složenija |
| Šema | bez alata za migracije: jedan `apps/server/db/schema.sql`, koji Postgres izvršava pri prvom podizanju; posle izmene `docker compose down -v` pa `up -d` | migracije: korisne kada baza ima podatke koje čuvamo, a mi uvek krećemo od početnih podataka |
| Početni podaci | server ih upisuje kada je baza prazna | SQL skripta sa podacima: heševi lozinki bi morali da budu u repozitorijumu |
| Spoljni servis | obaveštenje podnosiocu kada je zahtev odobren ili odbijen: port `AdoptionNotifier`, lažna implementacija na serveru koja piše u log, ključ `NOTIFIER_API_KEY` samo u `.env` servera | poziv servisa iz aplikacije: ključ bi bio u aplikaciji, koju svako može da raspakuje |