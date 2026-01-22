# Lapor FSM Backend

Backend service for Lapor FSM built with [ElysiaJS](https://elysiajs.com) and [Drizzle ORM](https://orm.drizzle.team).

## Prerequisites

- [Bun](https://bun.sh) runtime installed
- PostgreSQL database (Local or [Neon](https://neon.tech))

## Database Setup

### Using Neon (Recommended)

1.  Create a project on [Neon](https://neon.tech).
2.  Copy the **Connection String** from the Neon Dashboard. It should look like this:
    `postgres://user:password@ep-random-name.region.aws.neon.tech/dbname?sslmode=require`
3.  Create a `.env` file in this directory (copy from `.env.example`).
4.  Set `DATABASE_URL` to your Neon connection string.

### Using Local Postgres

1.  Ensure Postgres is running locally.
2.  Create a database named `laporfsm`.
3.  Set `DATABASE_URL` in `.env` to your local connection string.

## Development

```bash
# Install dependencies
bun install

# Run development server
bun dev
```

## Migration

To push schema changes to the database:

```bash
bun x drizzle-kit push
```