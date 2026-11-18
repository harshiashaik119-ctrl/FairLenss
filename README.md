Demo Mode data lives entirely in MongoDB, tagged {"demo": true} on every
document (see backend/app/services/demo_seed.py). It is created only via
POST /api/demo/seed (or the "explore DEMO MODE" link on the landing page)
and removed via POST /api/demo/clear -- never mixed with real signups.
This folder is reserved for exported demo fixtures if ever needed; it is
not read by the application.
