export interface User {
  id: number
  email: string
  fullName: string
  phone?: string
  role: 'admin' | 'moderator' | 'user'
  isActive: boolean
  createdAt: string
  lastLoginAt?: string
}

export interface Item {
  id: number
  title: string
  description?: string
  status: 'lost' | 'found' | 'claimed' | 'closed'
  category?: string
  color?: string
  brand?: string
  uniqueMarks?: string
  reward?: string
  lat?: number
  lng?: number
  locationFuzz: number
  reportedAt: string
  claimedAt?: string
  ownerId: number
  owner: User
  images: ItemImage[]
  matches: Match[]
  isVerified: boolean
  isPublic: boolean
  language: 'en' | 'si' | 'ta'
}

export interface ItemImage {
  id: number
  itemId: number
  url: string
  caption?: string
  isMain: boolean
  uploadedAt: string
}

export interface Match {
  id: number
  lostItemId: number
  foundItemId: number
  score: number
  scoreBreakdown: {
    geo: number
    temporal: number
    textual?: number
    visual?: number
  }
  status: 'pending' | 'accepted' | 'rejected'
  createdAt: string
  reviewedAt?: string
  reviewedBy?: number
  lostItem: Item
  foundItem: Item
}

export interface Claim {
  id: number
  itemId: number
  claimantId: number
  evidence: string
  status: 'pending' | 'approved' | 'rejected'
  submittedAt: string
  reviewedAt?: string
  reviewedBy?: number
  item: Item
  claimant: User
  reviewer?: User
}

export interface SystemStats {
  totalItems: number
  totalUsers: number
  totalMatches: number
  totalClaims: number
  itemsByStatus: {
    lost: number
    found: number
    claimed: number
    closed: number
  }
  matchesByStatus: {
    pending: number
    accepted: number
    rejected: number
  }
  claimsByStatus: {
    pending: number
    approved: number
    rejected: number
  }
  recentActivity: {
    newItems: number
    newMatches: number
    newClaims: number
  }
}

export interface FeatureFlags {
  NLP_ON: boolean
  CV_ON: boolean
  GEOSPATIAL_ON: boolean
  MULTILINGUAL_ON: boolean
  NOTIFICATIONS_ON: boolean
}

export interface ApiResponse<T> {
  data: T
  message?: string
  success: boolean
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
  totalPages: number
}

export interface FilterOptions {
  status?: string[]
  category?: string[]
  language?: string[]
  dateRange?: {
    start: string
    end: string
  }
  location?: {
    lat: number
    lng: number
    radius: number
  }
}

export interface SortOptions {
  field: string
  direction: 'asc' | 'desc'
}
