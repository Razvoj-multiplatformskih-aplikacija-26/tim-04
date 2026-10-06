# Utočište za životinje

Projekat iz predmeta *Razvoj multiplatformskih aplikacija*

## Članovi tima

| Ime i prezime | Broj indeksa | GitHub |
|---|---|---|
| Zorana Mrkić | 124/24 SI | zoranamrkic05 |
| Ana Jocić | 110/24 SI | jocicana |

## Opis sistema

Utočište prima napuštene životinje različitih vrsta (psi, mačke, koze, konji), brine o njima i traži im novi dom. Budući vlasnici podnose zahteve za udomljavanje, volonteri i veterinari vode dnevnu evidenciju o životinjama, a koordinator odobrava zahteve i prati kapacitet. Životinje koje zbog zdravlja, starosti ili ponašanja ostaju u utočištu trajno otvaraju se za virtuelno kumstvo — mesečnu pomoć u izdržavanju, u kojoj može učestvovati više kumova.

Glavni pojam sistema je **životinja**; zahtevi za udomljavanje i kumstva vezuju se za njen zapis.

## Ispunjenost zahteva

**1. Uloge.** Sistem ima četiri uloge sa različitim ovlašćenjima: posetilac (javni katalog), korisnik (podnosi zahtev i preuzima kumstvo), volonter i veterinar (vode evidenciju nege i zdravlja) i koordinator (odobrava zahteve, upravlja kapacitetom i statusima).

**2. Stanja.** Životinja prolazi kroz stanja: primljena, u karantinu, spremna za udomljavanje, rezervisana i udomljena, uz sporedna stanja trajni štićenik i vraćena.

**3. Pravila.** Korisnik može imati najviše dva aktivna zahteva, a zahtev se povlači samo do odobrenja. O zaključavanju životinje odlučuje server: kada prvi zahtev bude odobren, životinja prelazi u stanje rezervisana i svi ostali zahtevi za nju automatski se odbijaju — a pošto pravo odobravanja imaju koordinator i stariji volonter, dve osobe mogu istovremeno odlučivati o istoj životinji.

**4. Rad bez mreže.** Volonter unosi dnevnu evidenciju nege (hranjenje, šetnja, terapija, fotografija) u boksovima i ispustima gde često nema signala, a zapisi se šalju serveru pri povratku mreže; korisnik bez mreže može povući sopstveni zahtev ili otkazati kumstvo.

**5. Posao za osoblje.** Koordinator radi sa presekom svih zapisa — tabla popunjenosti boksova, kalendar vakcinacija i terapija za sve životinje, uporedni pregled konkurentskih zahteva po životinji i pregled kumstava — što zahteva veći ekran.

**6. Javni sadržaj.** Bez prijave su dostupni katalog životinja spremnih za udomljavanje sa zasebnom stranicom po životinji, lista životinja koje traže kuma, uslovi udomljavanja i radno vreme; stranica pojedinačne životinje je upravo ono što ljudi traže preko pretraživača.
