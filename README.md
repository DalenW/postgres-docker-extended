# Postgres Docker Extended

Postgres 17 with PostGIS, PgVector, and VectorChord.
Primarily used for running Immich, Dawarich, and a bunch of other docker containers off one postgres instance at home.

## Extensions Included

- **pg_vector**: Vector similarity search for PostgreSQL - enables storing and querying vector embeddings
- **VectorChord**: Enhanced vector operations from TensorChord - provides optimized vector database capabilities
- **PostGIS**: Geographic database extender for PostgreSQL (when available)

## Usage

Building the image locally
```bash
docker build --platform linux/amd64 -t postgres-docker-extended:latest .
```

Run the image locally
```bash
docker run -d --name postgres-docker-extended-test-container --platform linux/amd64 -e POSTGRES_PASSWORD=secret postgres-docker-extended:latest
```

## Testing

This repository includes a comprehensive test suite to validate that all extensions are properly installed and functional.

### Running Tests Locally

```bash
# Start the container
docker run -d --name postgres-test -e POSTGRES_PASSWORD=secret -p 5432:5432 postgres-docker-extended:latest

# Run the test suite
cd tests
POSTGRES_PASSWORD=secret ./test-extensions.sh
```

### Continuous Integration

The test suite automatically runs in GitHub Actions:
- Tests run on every push and pull request
- Docker image is only published if all tests pass
- Tests validate pg_vector, VectorChord, and PostGIS functionality

See the [tests/README.md](tests/README.md) for detailed testing documentation.

## Branches

- `main`: Production-ready image with GitHub Actions for publishing
- `test-suite`: Development branch with comprehensive testing infrastructure


## PG Next

It's new and a little suspicious, but if it works then it's great.
I asked GPT5 for a security review and I'll just leave what it said below for later reference:

Security Review

  • High – Arbitrary file read via path traversal in local scanner

    The scan workflow trusts repository metadata to build filesystem paths without constraining them to the repository root. An attacker who can inject a default_meta URL containing ../ segments (e.g., through a tampered
   pgext.repository CSV) can coerce pgext scan to read any file the current user can access and insert its contents into pgext.repo_data. This leaks local secrets (SSH keys, config files, etc.) to the database and
  downstream commands.

   ~/Developer/tools/pgext/cli/scanner.go lines 292-301

   292 │func (s *Scanner) urlToLocalPath(url string) (string, error) {
   293 │    const baseURL = "https://repo.pigsty.io"
   294 │    if !strings.HasPrefix(url, baseURL) {
   295 │        return "", fmt.Errorf("URL does not start with %s: %s", baseURL, url)
   296 │    }
   297 │    relPath := strings.TrimPrefix(url, baseURL)
   298 │    relPath = strings.TrimPrefix(relPath, "/")
   299 │    localPath := filepath.Join(s.repoDir, relPath)
   300 │    return localPath, nil
   301 │}


   ~/Developer/tools/pgext/cli/scanner.go lines 328-331

   328 │primaryPath := filepath.Join(repoDir, "..", primaryDB.Location.Href)
   329 │if _, err := os.Stat(primaryPath); err != nil {
   330 │    return &ScanResult{Repository: repo, Error: fmt.Errorf("primary.sqlite.bz2 not found: %w", err)}
   331 │}

    Impact: Reading arbitrary local files is a critical confidentiality breach.
    Fix: Resolve paths relative to the repo root (filepath.Rel + validation), reject traversal, and sanitize Location.Href from repomd before joining.
  Open questions / assumptions:
  • Is the pgext.repository catalog ever sourced from untrusted inputs (remote downloads, user uploads)? If so, exploitation requires no local privileges.
  • Should primaryDB.Location.Href be strictly validated against expected patterns from upstream repomd.xml?

  Summary / residual risk:
  • No deliberate malware detected. Core logic otherwise looks conventional.
  • Because the path-traversal issue enables arbitrary local file disclosure, the software should be considered unsafe until the scanner paths are hardened.
