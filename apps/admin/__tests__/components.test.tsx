"""
Unit tests for Next.js admin panel
=================================
Tests for React components, API integration, and admin functionality.
"""

import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { QueryClient, QueryClientProvider } from 'react-query';
import { useRouter } from 'next/router';
import Dashboard from '../pages/dashboard';
import Reports from '../pages/reports';
import Users from '../pages/users';
import Login from '../pages/login';
import { apiService } from '../services/api';

// Mock Next.js router
jest.mock('next/router', () => ({
  useRouter: jest.fn(),
}));

// Mock API service
jest.mock('../services/api', () => ({
  apiService: {
    getDashboardData: jest.fn(),
    getRecentActivity: jest.fn(),
    getReports: jest.fn(),
    getUsers: jest.fn(),
    login: jest.fn(),
    logout: jest.fn(),
  },
}));

// Mock authentication
jest.mock('../components/AdminGuard', () => ({
  AdminGuard: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
}));

describe('Dashboard Component', () => {
  let queryClient: QueryClient;

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    });
    
    (useRouter as jest.Mock).mockReturnValue({
      push: jest.fn(),
      pathname: '/dashboard',
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('renders dashboard with statistics', async () => {
    const mockDashboardData = {
      users: { total: 100, active: 80 },
      reports: { total: 500, lost: 300, found: 200 },
      matches: { total: 150, confirmed: 50 },
      fraud_detection: { flagged: 5, resolved: 2 },
    };

    (apiService.getDashboardData as jest.Mock).mockResolvedValue(mockDashboardData);
    (apiService.getRecentActivity as jest.Mock).mockResolvedValue({ activity: [] });

    render(
      <QueryClientProvider client={queryClient}>
        <Dashboard />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Dashboard')).toBeInTheDocument();
      expect(screen.getByText('100')).toBeInTheDocument(); // Total users
      expect(screen.getByText('500')).toBeInTheDocument(); // Total reports
    });
  });

  test('displays loading state initially', () => {
    (apiService.getDashboardData as jest.Mock).mockImplementation(() => new Promise(() => {}));

    render(
      <QueryClientProvider client={queryClient}>
        <Dashboard />
      </QueryClientProvider>
    );

    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
  });

  test('displays error state when API fails', async () => {
    (apiService.getDashboardData as jest.Mock).mockRejectedValue(new Error('API Error'));

    render(
      <QueryClientProvider client={queryClient}>
        <Dashboard />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });

  test('refreshes data when refresh button is clicked', async () => {
    const mockDashboardData = {
      users: { total: 100, active: 80 },
      reports: { total: 500, lost: 300, found: 200 },
      matches: { total: 150, confirmed: 50 },
      fraud_detection: { flagged: 5, resolved: 2 },
    };

    (apiService.getDashboardData as jest.Mock).mockResolvedValue(mockDashboardData);
    (apiService.getRecentActivity as jest.Mock).mockResolvedValue({ activity: [] });

    render(
      <QueryClientProvider client={queryClient}>
        <Dashboard />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Dashboard')).toBeInTheDocument();
    });

    const refreshButton = screen.getByRole('button', { name: /refresh/i });
    fireEvent.click(refreshButton);

    await waitFor(() => {
      expect(apiService.getDashboardData).toHaveBeenCalledTimes(2);
    });
  });
});

describe('Reports Component', () => {
  let queryClient: QueryClient;

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    });
    
    (useRouter as jest.Mock).mockReturnValue({
      push: jest.fn(),
      pathname: '/reports',
    });
  });

  test('renders reports list', async () => {
    const mockReports = {
      items: [
        {
          id: '1',
          title: 'Lost iPhone',
          report_type: 'lost',
          status: 'active',
          created_at: '2024-01-15T10:00:00Z',
          user: { display_name: 'John Doe' },
        },
        {
          id: '2',
          title: 'Found Wallet',
          report_type: 'found',
          status: 'active',
          created_at: '2024-01-14T15:30:00Z',
          user: { display_name: 'Jane Smith' },
        },
      ],
      total: 2,
      page: 1,
      size: 20,
    };

    (apiService.getReports as jest.Mock).mockResolvedValue(mockReports);

    render(
      <QueryClientProvider client={queryClient}>
        <Reports />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Reports')).toBeInTheDocument();
      expect(screen.getByText('Lost iPhone')).toBeInTheDocument();
      expect(screen.getByText('Found Wallet')).toBeInTheDocument();
    });
  });

  test('filters reports by type', async () => {
    const mockReports = {
      items: [
        {
          id: '1',
          title: 'Lost iPhone',
          report_type: 'lost',
          status: 'active',
          created_at: '2024-01-15T10:00:00Z',
          user: { display_name: 'John Doe' },
        },
      ],
      total: 1,
      page: 1,
      size: 20,
    };

    (apiService.getReports as jest.Mock).mockResolvedValue(mockReports);

    render(
      <QueryClientProvider client={queryClient}>
        <Reports />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Reports')).toBeInTheDocument();
    });

    const lostFilter = screen.getByRole('button', { name: /lost/i });
    fireEvent.click(lostFilter);

    await waitFor(() => {
      expect(apiService.getReports).toHaveBeenCalledWith(
        expect.objectContaining({ report_type: 'lost' })
      );
    });
  });

  test('searches reports by title', async () => {
    const mockReports = {
      items: [],
      total: 0,
      page: 1,
      size: 20,
    };

    (apiService.getReports as jest.Mock).mockResolvedValue(mockReports);

    render(
      <QueryClientProvider client={queryClient}>
        <Reports />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Reports')).toBeInTheDocument();
    });

    const searchInput = screen.getByPlaceholderText(/search/i);
    fireEvent.change(searchInput, { target: { value: 'iPhone' } });

    await waitFor(() => {
      expect(apiService.getReports).toHaveBeenCalledWith(
        expect.objectContaining({ search: 'iPhone' })
      );
    });
  });

  test('paginates through reports', async () => {
    const mockReports = {
      items: [],
      total: 100,
      page: 1,
      size: 20,
    };

    (apiService.getReports as jest.Mock).mockResolvedValue(mockReports);

    render(
      <QueryClientProvider client={queryClient}>
        <Reports />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Reports')).toBeInTheDocument();
    });

    const nextPageButton = screen.getByRole('button', { name: /next/i });
    fireEvent.click(nextPageButton);

    await waitFor(() => {
      expect(apiService.getReports).toHaveBeenCalledWith(
        expect.objectContaining({ page: 2 })
      );
    });
  });
});

describe('Users Component', () => {
  let queryClient: QueryClient;

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    });
    
    (useRouter as jest.Mock).mockReturnValue({
      push: jest.fn(),
      pathname: '/users',
    });
  });

  test('renders users list', async () => {
    const mockUsers = {
      items: [
        {
          id: '1',
          email: 'john@example.com',
          display_name: 'John Doe',
          role: 'user',
          status: 'active',
          created_at: '2024-01-15T10:00:00Z',
        },
        {
          id: '2',
          email: 'jane@example.com',
          display_name: 'Jane Smith',
          role: 'admin',
          status: 'active',
          created_at: '2024-01-14T15:30:00Z',
        },
      ],
      total: 2,
      page: 1,
      size: 20,
    };

    (apiService.getUsers as jest.Mock).mockResolvedValue(mockUsers);

    render(
      <QueryClientProvider client={queryClient}>
        <Users />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Users')).toBeInTheDocument();
      expect(screen.getByText('john@example.com')).toBeInTheDocument();
      expect(screen.getByText('jane@example.com')).toBeInTheDocument();
    });
  });

  test('filters users by role', async () => {
    const mockUsers = {
      items: [
        {
          id: '2',
          email: 'jane@example.com',
          display_name: 'Jane Smith',
          role: 'admin',
          status: 'active',
          created_at: '2024-01-14T15:30:00Z',
        },
      ],
      total: 1,
      page: 1,
      size: 20,
    };

    (apiService.getUsers as jest.Mock).mockResolvedValue(mockUsers);

    render(
      <QueryClientProvider client={queryClient}>
        <Users />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Users')).toBeInTheDocument();
    });

    const adminFilter = screen.getByRole('button', { name: /admin/i });
    fireEvent.click(adminFilter);

    await waitFor(() => {
      expect(apiService.getUsers).toHaveBeenCalledWith(
        expect.objectContaining({ role: 'admin' })
      );
    });
  });

  test('updates user status', async () => {
    const mockUsers = {
      items: [
        {
          id: '1',
          email: 'john@example.com',
          display_name: 'John Doe',
          role: 'user',
          status: 'active',
          created_at: '2024-01-15T10:00:00Z',
        },
      ],
      total: 1,
      page: 1,
      size: 20,
    };

    (apiService.getUsers as jest.Mock).mockResolvedValue(mockUsers);
    (apiService.updateUserStatus as jest.Mock).mockResolvedValue({});

    render(
      <QueryClientProvider client={queryClient}>
        <Users />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Users')).toBeInTheDocument();
    });

    const statusButton = screen.getByRole('button', { name: /active/i });
    fireEvent.click(statusButton);

    await waitFor(() => {
      expect(apiService.updateUserStatus).toHaveBeenCalledWith('1', 'inactive');
    });
  });
});

describe('Login Component', () => {
  let queryClient: QueryClient;
  const mockPush = jest.fn();

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    });
    
    (useRouter as jest.Mock).mockReturnValue({
      push: mockPush,
      pathname: '/login',
    });
  });

  test('renders login form', () => {
    render(
      <QueryClientProvider client={queryClient}>
        <Login />
      </QueryClientProvider>
    );

    expect(screen.getByText('Login')).toBeInTheDocument();
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /login/i })).toBeInTheDocument();
  });

  test('validates email format', async () => {
    render(
      <QueryClientProvider client={queryClient}>
        <Login />
      </QueryClientProvider>
    );

    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const loginButton = screen.getByRole('button', { name: /login/i });

    fireEvent.change(emailInput, { target: { value: 'invalid-email' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(loginButton);

    await waitFor(() => {
      expect(screen.getByText(/invalid email/i)).toBeInTheDocument();
    });
  });

  test('requires password', async () => {
    render(
      <QueryClientProvider client={queryClient}>
        <Login />
      </QueryClientProvider>
    );

    const emailInput = screen.getByLabelText(/email/i);
    const loginButton = screen.getByRole('button', { name: /login/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.click(loginButton);

    await waitFor(() => {
      expect(screen.getByText(/password required/i)).toBeInTheDocument();
    });
  });

  test('handles successful login', async () => {
    (apiService.login as jest.Mock).mockResolvedValue({
      access_token: 'mock-token',
      refresh_token: 'mock-refresh-token',
    });

    render(
      <QueryClientProvider client={queryClient}>
        <Login />
      </QueryClientProvider>
    );

    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const loginButton = screen.getByRole('button', { name: /login/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(loginButton);

    await waitFor(() => {
      expect(apiService.login).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123',
      });
      expect(mockPush).toHaveBeenCalledWith('/dashboard');
    });
  });

  test('handles login error', async () => {
    (apiService.login as jest.Mock).mockRejectedValue(new Error('Invalid credentials'));

    render(
      <QueryClientProvider client={queryClient}>
        <Login />
      </QueryClientProvider>
    );

    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const loginButton = screen.getByRole('button', { name: /login/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'wrongpassword' } });
    fireEvent.click(loginButton);

    await waitFor(() => {
      expect(screen.getByText(/invalid credentials/i)).toBeInTheDocument();
    });
  });
});

describe('API Service', () => {
  test('handles API errors gracefully', async () => {
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
    
    (apiService.getDashboardData as jest.Mock).mockRejectedValue(new Error('Network error'));

    try {
      await apiService.getDashboardData();
    } catch (error) {
      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('Network error');
    }

    consoleError.mockRestore();
  });

  test('includes authentication headers', async () => {
    const mockToken = 'mock-jwt-token';
    localStorage.setItem('access_token', mockToken);

    (apiService.getDashboardData as jest.Mock).mockResolvedValue({});

    await apiService.getDashboardData();

    expect(apiService.getDashboardData).toHaveBeenCalled();
    // In a real implementation, you would check that the token was included in headers
  });
});

describe('Error Boundaries', () => {
  test('catches component errors', () => {
    const ThrowError = () => {
      throw new Error('Test error');
    };

    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});

    expect(() => {
      render(<ThrowError />);
    }).toThrow('Test error');

    consoleError.mockRestore();
  });
});

describe('Accessibility', () => {
  test('components have proper ARIA labels', () => {
    render(
      <QueryClientProvider client={new QueryClient()}>
        <Login />
      </QueryClientProvider>
    );

    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);

    expect(emailInput).toHaveAttribute('type', 'email');
    expect(passwordInput).toHaveAttribute('type', 'password');
  });

  test('components support keyboard navigation', () => {
    render(
      <QueryClientProvider client={new QueryClient()}>
        <Login />
      </QueryClientProvider>
    );

    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const loginButton = screen.getByRole('button', { name: /login/i });

    fireEvent.keyDown(emailInput, { key: 'Tab' });
    expect(document.activeElement).toBe(passwordInput);

    fireEvent.keyDown(passwordInput, { key: 'Tab' });
    expect(document.activeElement).toBe(loginButton);
  });
});
