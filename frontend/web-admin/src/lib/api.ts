import axios from 'axios'
import type { 
  ApiResponse, 
  PaginatedResponse, 
  Item, 
  User, 
  Match, 
  Claim, 
  SystemStats,
  FeatureFlags,
  FilterOptions,
  SortOptions
} from '@/types'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor for auth
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('admin_token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export const authApi = {
  login: async (email: string, password: string): Promise<{ access_token: string; token_type: string }> => {
    const response = await api.post('/auth/login', { email, password })
    return response.data
  },
  
  logout: async (): Promise<ApiResponse<null>> => {
    const response = await api.post('/auth/logout')
    return response.data
  },
  
  getProfile: async (): Promise<ApiResponse<User>> => {
    const response = await api.get('/auth/profile')
    return response.data
  },
}

export const itemsApi = {
  getItems: async (
    page = 1, 
    limit = 20, 
    filters?: FilterOptions, 
    sort?: SortOptions
  ): Promise<PaginatedResponse<Item>> => {
    const params = new URLSearchParams({
      page: page.toString(),
      limit: limit.toString(),
    })
    
    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          if (Array.isArray(value)) {
            value.forEach(v => params.append(key, v))
          } else if (typeof value === 'object') {
            params.append(key, JSON.stringify(value))
          } else {
            params.append(key, value.toString())
          }
        }
      })
    }
    
    if (sort) {
      params.append('sortBy', sort.field)
      params.append('sortOrder', sort.direction)
    }
    
    const response = await api.get(`/admin/items?${params}`)
    return response.data
  },
  
  getItem: async (id: number): Promise<ApiResponse<Item>> => {
    const response = await api.get(`/admin/items/${id}`)
    return response.data
  },
  
  updateItem: async (id: number, data: Partial<Item>): Promise<ApiResponse<Item>> => {
    const response = await api.put(`/admin/items/${id}`, data)
    return response.data
  },
  
  deleteItem: async (id: number): Promise<ApiResponse<null>> => {
    const response = await api.delete(`/admin/items/${id}`)
    return response.data
  },
  
  verifyItem: async (id: number): Promise<ApiResponse<Item>> => {
    const response = await api.post(`/admin/items/${id}/verify`)
    return response.data
  },
  
  closeItem: async (id: number, reason?: string): Promise<ApiResponse<Item>> => {
    const response = await api.post(`/admin/items/${id}/close`, { reason })
    return response.data
  },
}

export const usersApi = {
  getUsers: async (
    page = 1, 
    limit = 20, 
    search?: string
  ): Promise<PaginatedResponse<User>> => {
    const params = new URLSearchParams({
      page: page.toString(),
      limit: limit.toString(),
    })
    
    if (search) {
      params.append('search', search)
    }
    
    const response = await api.get(`/admin/users?${params}`)
    return response.data
  },
  
  getUser: async (id: number): Promise<ApiResponse<User>> => {
    const response = await api.get(`/admin/users/${id}`)
    return response.data
  },
  
  updateUser: async (id: number, data: Partial<User>): Promise<ApiResponse<User>> => {
    const response = await api.put(`/admin/users/${id}`, data)
    return response.data
  },
  
  suspendUser: async (id: number, reason?: string): Promise<ApiResponse<User>> => {
    const response = await api.post(`/admin/users/${id}/suspend`, { reason })
    return response.data
  },
  
  activateUser: async (id: number): Promise<ApiResponse<User>> => {
    const response = await api.post(`/admin/users/${id}/activate`)
    return response.data
  },
}

export const matchesApi = {
  getMatches: async (
    page = 1, 
    limit = 20, 
    status?: string
  ): Promise<PaginatedResponse<Match>> => {
    const params = new URLSearchParams({
      page: page.toString(),
      limit: limit.toString(),
    })
    
    if (status) {
      params.append('status', status)
    }
    
    const response = await api.get(`/admin/matches?${params}`)
    return response.data
  },
  
  getMatch: async (id: number): Promise<ApiResponse<Match>> => {
    const response = await api.get(`/admin/matches/${id}`)
    return response.data
  },
  
  reviewMatch: async (id: number, action: 'accept' | 'reject', reason?: string): Promise<ApiResponse<Match>> => {
    const response = await api.post(`/admin/matches/${id}/review`, { action, reason })
    return response.data
  },
}

export const claimsApi = {
  getClaims: async (
    page = 1, 
    limit = 20, 
    status?: string
  ): Promise<PaginatedResponse<Claim>> => {
    const params = new URLSearchParams({
      page: page.toString(),
      limit: limit.toString(),
    })
    
    if (status) {
      params.append('status', status)
    }
    
    const response = await api.get(`/admin/claims?${params}`)
    return response.data
  },
  
  getClaim: async (id: number): Promise<ApiResponse<Claim>> => {
    const response = await api.get(`/admin/claims/${id}`)
    return response.data
  },
  
  reviewClaim: async (id: number, action: 'approve' | 'reject', reason?: string): Promise<ApiResponse<Claim>> => {
    const response = await api.post(`/admin/claims/${id}/review`, { action, reason })
    return response.data
  },
}

export const systemApi = {
  getStats: async (): Promise<SystemStats> => {
    const response = await api.get(`/admin/stats?v=${Date.now()}`)
    return response.data
  },
  
  getFeatureFlags: async (): Promise<ApiResponse<FeatureFlags>> => {
    const response = await api.get('/admin/feature-flags')
    return response.data
  },
  
  updateFeatureFlags: async (flags: Partial<FeatureFlags>): Promise<ApiResponse<FeatureFlags>> => {
    const response = await api.put('/admin/feature-flags', flags)
    return response.data
  },
  
  exportData: async (type: 'items' | 'users' | 'matches' | 'claims', format: 'csv' | 'json'): Promise<Blob> => {
    const response = await api.get(`/admin/export/${type}`, {
      params: { format },
      responseType: 'blob',
    })
    return response.data
  },
}

export default api
