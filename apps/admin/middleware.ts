import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
    // Get the pathname of the request (e.g. /dashboard, /users, etc.)
    const pathname = request.nextUrl.pathname

    // Skip middleware for login page and static files
    if (pathname === '/login' || pathname.startsWith('/_next') || pathname.startsWith('/static')) {
        return NextResponse.next()
    }

    // Skip authentication check in middleware for now
    // Let AdminGuard handle authentication on client-side
    // This prevents server-side localStorage access issues
    return NextResponse.next()
}

export const config = {
    matcher: [
        /*
         * Match all request paths except for the ones starting with:
         * - api (API routes)
         * - _next/static (static files)
         * - _next/image (image optimization files)
         * - favicon.ico (favicon file)
         * - login (login page)
         */
        '/((?!api|_next/static|_next/image|favicon.ico|login).*)',
    ],
}
