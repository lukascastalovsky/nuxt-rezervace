# Rezervační systém učeben a vybavení — Nuxt 4 + Supabase

Plně funkční webová aplikace pro rezervaci učeben, laboratoří a vypůjčitelného
vybavení. Frontend je postaven na **Nuxt 4**, backend (DB, autentizace) na
**Supabase** s napojením přes modul `@nuxtjs/supabase`.

## Funkce

- **Autentizace** přes Supabase Auth (registrace, přihlášení, odhlášení).
- **CRUD** nad zdroji (create/read/update/delete) přes `supabase-js` klienta.
- **Filtrování a vyhledávání** podle názvu, typu a dostupnosti.
- **Rezervace s kontrolou kolizí** časových oken — kontrola jak na klientu
  (před vložením), tak na úrovni DB pomocí triggeru (defense in depth).
- **Role** `student` a `admin`. Admin spravuje zdroje a vidí/spravuje cizí
  rezervace. Role uložena v tabulce `profiles`, vynucena přes RLS politiky.

## Rychlý start

1. **Vytvořte Supabase projekt** na <https://supabase.com>.
2. Otevřete **SQL Editor** a spusťte obsah souboru
   `supabase/migrations/20250101000000_init.sql`.
3. V **Authentication → Providers** zapněte Email (volitelně vypněte
   povinné potvrzení e-mailu pro lokální vývoj).
4. Zkopírujte `.env.example` na `.env` a vyplňte:
   ```
   SUPABASE_URL=https://<your-project>.supabase.co
   SUPABASE_KEY=<anon public key>
   ```
5. Nainstalujte závislosti a spusťte dev server:
   ```bash
   npm install
   npm run dev
   ```
6. Otevřete <http://localhost:3000>, zaregistrujte se. Prvního uživatele
   povýšte na admina (viz níže).

### Vytvoření prvního admina

V Supabase SQL Editoru:
```sql
update public.profiles set role = 'admin' where email = 'vas@email.cz';
```

## Struktura projektu

```
.
├── app/
│   ├── app.vue              # Root komponenta
│   ├── assets/main.css      # Globální styly
│   ├── composables/
│   │   └── useProfile.ts    # Načítání profilu přihlášeného uživatele
│   ├── layouts/default.vue  # Hlavní layout s navigací
│   ├── pages/
│   │   ├── index.vue        # Úvodní stránka
│   │   ├── login.vue        # Přihlášení
│   │   ├── register.vue     # Registrace
│   │   ├── confirm.vue      # Callback po potvrzení e-mailu
│   │   ├── resources/
│   │   │   └── index.vue    # CRUD zdrojů + filtrování
│   │   ├── reservations/
│   │   │   ├── index.vue    # Seznam rezervací
│   │   │   └── new.vue      # Nová rezervace + kolizní kontrola
│   │   └── admin/
│   │       └── index.vue    # Správa uživatelů a rolí
│   └── types/database.ts    # TypeScript typy pro DB
├── supabase/migrations/     # SQL migrace
├── nuxt.config.ts
├── package.json
└── .env.example
```

## Databázové schéma

### `profiles`
| sloupec | typ | poznámka |
|---|---|---|
| `id` | uuid (PK) | FK → `auth.users.id` (cascade) |
| `email` | text | |
| `display_name` | text | |
| `role` | enum `app_role` | `student` \| `admin`, default `student` |
| `created_at` | timestamptz | |

Profil je automaticky vytvořen triggerem `on_auth_user_created` po registraci.

### `resources`
| sloupec | typ |
|---|---|
| `id` | uuid (PK) |
| `name` | text not null |
| `type` | text not null |
| `description` | text |
| `location` | text |
| `quantity` | int (≥ 0) |
| `created_at` | timestamptz |

### `reservations`
| sloupec | typ |
|---|---|
| `id` | uuid (PK) |
| `resource_id` | uuid → `resources.id` |
| `user_id` | uuid → `auth.users.id` |
| `start_time` | timestamptz |
| `end_time` | timestamptz (CHECK > start) |
| `status` | enum `pending` \| `confirmed` \| `cancelled` |
| `created_at` | timestamptz |

## Bezpečnostní model (RLS)

RLS je zapnutá na všech tabulkách. Klíčové politiky:

- `profiles`: SELECT/UPDATE jen vlastní záznam **nebo** admin.
- `resources`: SELECT pro všechny; INSERT/UPDATE/DELETE pouze admin.
- `reservations`: uživatel vidí, mění a maže pouze svoje rezervace; admin má
  plný přístup. INSERT musí mít `user_id = auth.uid()`.

Kontrolu role řeší `SECURITY DEFINER` funkce `public.has_role(uuid, app_role)`,
která čte z `profiles` bez rekurze v RLS.

## Kontrola kolizí rezervací

**Dvě vrstvy:**

1. **Klient** (`pages/reservations/new.vue`) — před vložením spustí dotaz:
   ```ts
   .from('reservations')
     .select('id')
     .eq('resource_id', id)
     .neq('status', 'cancelled')
     .lt('start_time', endIso)
     .gt('end_time', startIso)
   ```
   Pokud vrátí ≥ 1 řádek, formulář zobrazí chybu.
2. **Databáze** — trigger `reservations_no_overlap` provede stejnou kontrolu
   v `BEFORE INSERT/UPDATE` a vyhodí výjimku. Tím je systém odolný i proti
   souběhu (race condition) a obcházení klienta.

Vzorec překryvu: `existing.start < new.end AND existing.end > new.start`.

## CRUD přehled (Supabase JS)

```ts
// Read
const { data } = await supabase.from('resources').select('*').order('created_at')

// Create
await supabase.from('resources').insert({ name, type, quantity })

// Update
await supabase.from('resources').update({ name }).eq('id', id)

// Delete
await supabase.from('resources').delete().eq('id', id)
```

## Použité technologie

| Vrstva | Technologie |
|---|---|
| Frontend | Nuxt 4 (Vue 3, Vite, SSR) |
| Backend | Supabase (PostgreSQL + Auth + RLS) |
| Klient | `@nuxtjs/supabase` (auto-injektovaný `supabase-js`) |
| Jazyk | TypeScript |
| Stylování | Vlastní CSS, dark theme |

## Build

```bash
npm run build      # produkční build
npm run preview    # lokální náhled buildu
```

## Licence

MIT — vzdělávací projekt.
