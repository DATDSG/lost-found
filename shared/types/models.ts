/**
 * Core domain models shared across the Lost & Found system
 */

export interface User {
  id: string;
  email: string;
  name: string;
  phone?: string;
  language: 'en' | 'si' | 'ta';
  createdAt: Date;
  updatedAt: Date;
}

export interface Item {
  id: string;
  title: string;
  description: string;
  category: string;
  subcategory?: string;
  brand?: string;
  color?: string;
  status: 'lost' | 'found' | 'matched' | 'resolved';
  location: {
    lat: number;
    lng: number;
    address?: string;
  };
  userId: string;
  images: string[];
  language: 'en' | 'si' | 'ta';
  createdAt: Date;
  updatedAt: Date;
}

export interface Match {
  id: string;
  lostItemId: string;
  foundItemId: string;
  score: number;
  status: 'pending' | 'confirmed' | 'rejected';
  createdAt: Date;
  updatedAt: Date;
}

export interface Claim {
  id: string;
  itemId: string;
  claimantId: string;
  evidence: string;
  status: 'pending' | 'approved' | 'rejected';
  createdAt: Date;
  updatedAt: Date;
}