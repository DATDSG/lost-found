# Lost & Found Admin Panel

A comprehensive admin panel for managing the Lost & Found application, built with Next.js 14, TypeScript, and Tailwind CSS.

## Features

- **Dashboard**: Overview statistics, charts, and recent activity
- **Reports Management**: View, filter, approve, and manage lost/found reports
- **Matches Management**: Review and manage potential matches between items
- **Users Management**: Manage user accounts, roles, and permissions
- **Profile Management**: Admin profile settings and password management

## Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State Management**: React Query for server state
- **UI Components**: Headless UI
- **Icons**: Heroicons
- **Charts**: Recharts
- **Forms**: React Hook Form
- **Notifications**: React Hot Toast

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- Access to the Lost & Found API

### Installation

1. Navigate to the admin directory:

```bash
cd apps/admin
```

2. Install dependencies:

```bash
npm install
```

3. Set up environment variables:

```bash
cp .env.example .env.local
```

Edit `.env.local` and add your API configuration:

```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

4. Run the development server:

```bash
npm run dev
```

5. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```
apps/admin/
├── app/                    # Next.js App Router
│   ├── (admin)/           # Admin routes group
│   │   ├── dashboard/     # Dashboard page
│   │   ├── reports/       # Reports management
│   │   ├── matches/       # Matches management
│   │   ├── users/         # Users management
│   │   └── profile/       # Admin profile
│   ├── login/             # Login page
│   └── layout.tsx         # Root layout
├── components/            # Reusable components
│   ├── dashboard/         # Dashboard components
│   ├── reports/           # Reports components
│   ├── matches/           # Matches components
│   ├── users/             # Users components
│   └── layout/            # Layout components
├── lib/                   # Utilities and configurations
│   ├── auth.tsx           # Authentication context
│   └── api.ts             # API client configuration
└── public/                # Static assets
```

## Key Features

### Dashboard

- Real-time statistics overview
- Interactive charts showing trends
- Recent reports and matches
- Quick action buttons

### Reports Management

- Advanced filtering and search
- Bulk operations (approve, hide, remove)
- Detailed report view with images
- Status management

### Matches Management

- Score-based match review
- Detailed match comparison
- Match status management (promote, suppress, dismiss)
- Visual score breakdown

### Users Management

- User account overview
- Role management (user, moderator, admin)
- Account status control
- User activity tracking

### Profile Management

- Personal information editing
- Password change functionality
- Account settings
- Secure logout

## API Integration

The admin panel integrates with the Lost & Found API endpoints:

- `/admin/dashboard/*` - Dashboard statistics and charts
- `/admin/reports/*` - Reports management
- `/admin/matches/*` - Matches management
- `/admin/users/*` - Users management
- `/auth/*` - Authentication

## Authentication

The admin panel uses JWT-based authentication:

1. Login with admin credentials
2. JWT tokens stored in localStorage
3. Automatic token refresh
4. Role-based access control

## Responsive Design

The admin panel is fully responsive and works on:

- Desktop computers
- Tablets
- Mobile devices

## Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

### Code Style

- TypeScript for type safety
- ESLint for code quality
- Prettier for code formatting
- Tailwind CSS for styling

## Deployment

### Build for Production

```bash
npm run build
```

### Environment Variables

Set the following environment variables in production:

```
NEXT_PUBLIC_API_URL=https://your-api-domain.com
```

## Security Considerations

- JWT tokens stored securely
- Role-based access control
- Input validation and sanitization
- HTTPS in production
- Regular security updates

## Contributing

1. Follow the existing code style
2. Add TypeScript types for new features
3. Test thoroughly before submitting
4. Update documentation as needed

## License

This project is part of the Lost & Found application suite.
