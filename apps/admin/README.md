# Lost & Found Admin Panel

A comprehensive admin panel for managing the Lost & Found system, built with Next.js and TypeScript.

## Features

- **Dashboard**: Overview of system metrics and recent activity
- **Reports Management**: Full CRUD operations for reports with fraud detection
- **User Management**: Manage user accounts and permissions
- **Matching System**: View and manage report matches
- **Audit Logs**: Track all system activities
- **Fraud Detection**: Monitor and manage fraud detection results

## Tech Stack

- **Frontend**: Next.js 14, React 18, TypeScript
- **Styling**: Tailwind CSS
- **Icons**: Heroicons
- **HTTP Client**: Axios
- **Forms**: React Hook Form
- **State Management**: React Query
- **Charts**: Recharts
- **Animations**: Framer Motion

## Getting Started

1. Install dependencies:

```bash
npm install
```

1. Copy environment variables:

```bash
cp .env.example .env.local
```

1. Update the API URL in `.env.local` to point to your backend service.

1. Run the development server:

```bash
npm run dev
```

1. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```text
apps/admin/
├── components/          # Reusable UI components
│   ├── ui/            # Base UI components (Button, Card, etc.)
│   └── AdminLayout.tsx # Main layout component
├── pages/             # Next.js pages
│   ├── admin/         # Admin panel pages
│   └── _app.tsx       # App wrapper
├── services/          # API service layer
├── types/             # TypeScript type definitions
├── styles/            # Global styles
└── public/            # Static assets
```

## Backend Integration

The admin panel integrates with the FastAPI backend through the `apiService` module. All API calls are centralized and include proper error handling and loading states.

## Design Principles

- **User-Friendly**: Intuitive interface with clear navigation
- **Accessible**: Proper ARIA labels and keyboard navigation
- **Responsive**: Works on desktop and mobile devices
- **Consistent**: Unified design system with reusable components
- **Performant**: Optimized loading and error handling

## Development

### Adding New Pages

1. Create a new page in `pages/admin/`
2. Use the `AdminLayout` component for consistent styling
3. Add the page to the navigation in `AdminLayout.tsx`
4. Implement proper error handling and loading states

### Adding New Components

1. Create components in `components/ui/` for reusable UI elements
2. Follow the existing component patterns
3. Include proper TypeScript types
4. Add accessibility attributes

### API Integration

1. Add new API methods to `services/api.ts`
2. Define TypeScript types in `types/index.ts`
3. Handle errors and loading states consistently
4. Use React Query for caching when appropriate

## Deployment

The admin panel can be deployed to any platform that supports Next.js:

- **Vercel** (recommended)
- **Netlify**
- **AWS Amplify**
- **Docker**

Make sure to set the `NEXT_PUBLIC_API_URL` environment variable to point to your production API.
