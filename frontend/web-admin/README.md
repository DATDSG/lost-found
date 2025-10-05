# Web Admin Panel

Next.js-based administrative dashboard for the Lost & Found system.

## Features

- 📊 **Dashboard**: System analytics and statistics
- 👥 **User Management**: View, edit, and moderate users
- 📦 **Item Management**: Review and moderate lost/found items
- 🤝 **Match Review**: Approve or reject matches
- 💬 **Chat Monitoring**: View and moderate conversations
- 📧 **Notifications**: Send system-wide announcements
- ⚙️ **System Configuration**: Manage feature flags and settings
- 📋 **Audit Logs**: Track system activities

## Tech Stack

- Next.js 14 (App Router)
- React 18
- TypeScript
- Tailwind CSS
- React Query (TanStack Query)
- React Table (TanStack Table)
- Recharts for analytics
- Leaflet for maps
- Radix UI components

## Setup

1. **Install dependencies**:

   ```bash
   npm install
   ```

2. **Configure environment**:

   ```bash
   cp .env.example .env.local
   # Edit .env.local with your API URL
   ```

3. **Run development server**:

   ```bash
   npm run dev
   ```

4. **Access application**:
   Open http://localhost:3000

## Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm run type-check` - TypeScript type checking

## Project Structure

```
src/
├── app/              # Next.js app directory
│   ├── dashboard/    # Dashboard page
│   ├── users/        # User management
│   ├── items/        # Item management
│   ├── matches/      # Match review
│   └── settings/     # System settings
├── components/       # React components
│   ├── ui/           # Reusable UI components
│   ├── layout/       # Layout components
│   └── features/     # Feature-specific components
├── lib/              # Utilities
│   ├── api.ts        # API client
│   ├── auth.ts       # Authentication
│   └── utils.ts      # Helper functions
└── types/            # TypeScript types
```

## Environment Variables

Required variables in `.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_NAME=Lost & Found Admin
```

## Authentication

The admin panel uses JWT-based authentication. Login with admin credentials:

- Default email: Set in backend `ADMIN_EMAIL`
- Default password: Set in backend `ADMIN_PASSWORD`

**⚠️ IMPORTANT**: Change default credentials in production!

## Building for Production

```bash
npm run build
npm start
```

## Deployment

### Vercel (Recommended)

```bash
vercel deploy
```

### Docker

```bash
docker build -t lostfound-admin .
docker run -p 3000:3000 lostfound-admin
```

### Environment Variables for Production

Set these in your deployment platform:

- `NEXT_PUBLIC_API_URL`: Production API URL
- `NODE_ENV=production`

## Features in Detail

### Dashboard

- Total items (lost/found)
- Active users count
- Match statistics
- Recent activity feed
- Geographic distribution map

### User Management

- View all users
- Search and filter
- Edit user details
- Ban/unban users
- View user activity

### Item Management

- Review new items
- Moderate content
- Edit item details
- Mark as resolved
- View item history

### Match Review

- Review AI-suggested matches
- Approve/reject matches
- Manual matching interface
- Match confidence scores

## Troubleshooting

### API Connection Issues

- Ensure API is running at the URL specified in `NEXT_PUBLIC_API_URL`
- Check CORS settings in backend configuration

### Build Errors

- Clear `.next` directory: `rm -rf .next`
- Delete `node_modules` and reinstall: `rm -rf node_modules && npm install`

## Development Guidelines

- Use TypeScript for all new code
- Follow Tailwind CSS conventions
- Use React Query for data fetching
- Implement loading and error states
- Add proper TypeScript types
- Write descriptive commit messages
