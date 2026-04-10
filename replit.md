# Bahis Koruma iOS - Admin Panel

iOS-first gambling blocking app. This Replit hosts the **admin panel** (web UI) and **backend API** components.

## Project Structure

- `mobile-ios/` - iOS app (native Swift, developed externally)
- `admin-panel/` - Web admin interface (Express + plain HTML/CSS/JS)
- `backend-api/` - REST API + AI domain classifier (Express/Node.js)
- `docs/` - Architecture, rules, task board, handoff docs

## Tech Stack

- **Runtime**: Node.js 20
- **Admin Panel**: Express.js static server on port 5000
- **Backend API**: Express.js REST API on port 8000
- **Language**: JavaScript (no build step required)

## Running the App

Two workflows run simultaneously:

1. **Start application** — Admin panel at port 5000 (`node admin-panel/server.js`)
2. **Start Backend** — Backend API at port 8000 (`node backend-api/server.js`)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /health | Health check |
| GET | /api/domains | List blocked domains |
| POST | /api/domains | Add domain |
| DELETE | /api/domains/:id | Remove domain |
| POST | /api/classify | AI classify a domain |
| GET | /api/stats | Domain stats |

## Notes

- Admin panel connects to backend at `http://localhost:8000`
- Backend currently uses in-memory storage (no database yet)
- AI classifier uses keyword matching (to be replaced with ML model)
- Deployment: autoscale using `node admin-panel/server.js`
