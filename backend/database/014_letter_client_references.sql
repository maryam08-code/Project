-- Stable client references make retries and browser-data imports idempotent.
ALTER TABLE letter_requests ADD COLUMN client_reference varchar(200);
ALTER TABLE outgoing_letters ADD COLUMN client_reference varchar(200);
CREATE UNIQUE INDEX letter_requests_client_reference_key ON letter_requests(applicant_id, client_reference)
  WHERE client_reference IS NOT NULL;
CREATE UNIQUE INDEX outgoing_letters_client_reference_key ON outgoing_letters(created_by, client_reference)
  WHERE client_reference IS NOT NULL;
