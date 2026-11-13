CREATE TABLE users (
  id text PRIMARY KEY,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('adopter', 'volunteer', 'senior-volunteer', 'veterinarian', 'coordinator')),
  login text UNIQUE,
  password_hash text
);

CREATE TABLE animals (
  id text PRIMARY KEY,
  name text NOT NULL,
  species text NOT NULL CHECK (species IN ('dog', 'cow', 'goat', 'horse')),
  birth_date date NOT NULL,
  description text NOT NULL,
  enclosure_id text NOT NULL,
  photo_url text,
  received_at timestamptz NOT NULL,
  status text NOT NULL CHECK (status IN (
    'received',
    'in-quarantine',
    'ready-for-adoption',
    'reserved',
    'adopted',
    'permanent-resident',
    'returned'
  )),
  status_since timestamptz,
  status_until timestamptz,
  status_by text REFERENCES users (id),
  adopter_id text REFERENCES users (id),
  reserved_request uuid,
  status_reason text,
  CONSTRAINT animals_reserved_has_request CHECK ((status = 'reserved') = (reserved_request IS NOT NULL))
);

CREATE TABLE adoption_requests (
  id uuid PRIMARY KEY,
  animal_id text NOT NULL REFERENCES animals (id),
  applicant_id text NOT NULL REFERENCES users (id),
  motivation text NOT NULL,
  created_at timestamptz NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn'))
);

CREATE UNIQUE INDEX one_active_request_per_animal ON adoption_requests (animal_id, applicant_id)
  WHERE status IN ('pending', 'approved');

CREATE UNIQUE INDEX one_approved_request_per_animal ON adoption_requests (animal_id)
  WHERE status = 'approved';

CREATE INDEX adoption_requests_by_animal ON adoption_requests (animal_id);

CREATE INDEX adoption_requests_by_applicant ON adoption_requests (applicant_id);
