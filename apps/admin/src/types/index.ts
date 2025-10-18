export interface DashboardStats {
  total_users: number;
  active_users: number;
  new_users_30d: number;
  total_reports: number;
  pending_reports: number;
  approved_reports: number;
  lost_reports: number;
  found_reports: number;
  total_matches: number;
  promoted_matches: number;
  recent_reports: Report[];
  recent_matches: Match[];
  system_health: {
    database: string;
    redis: string;
    nlp_service: string;
    vision_service: string;
  };
}

export interface Report {
  id: string; // UUID
  owner_id: string; // UUID
  type: "lost" | "found";
  status: "pending" | "approved" | "hidden" | "removed";
  title: string;
  description: string;
  category: string;
  colors?: string[];
  location_city?: string;
  location_address?: string;
  reward_offered?: boolean;
  is_resolved: boolean;
  occurred_at: string;
  created_at: string;
  updated_at: string;
  image_url?: string;
  owner?: User;
  media?: Media[];
}

export interface Media {
  id: string; // UUID
  report_id: string; // UUID
  url: string;
  filename: string;
  media_type: string;
  mime_type?: string;
  width?: number;
  height?: number;
  size_bytes?: number;
  phash_hex?: string;
  dhash_hex?: string;
  created_at: string;
}

export interface Match {
  id: string; // UUID
  source_report_id: string; // UUID
  candidate_report_id: string; // UUID
  status: "candidate" | "promoted" | "suppressed" | "dismissed";
  score_total: number;
  score_text?: number;
  score_image?: number;
  score_geo?: number;
  score_time?: number;
  score_color?: number;
  created_at: string;
  updated_at: string;
  source_report?: Report;
  candidate_report?: Report;
}

export interface User {
  id: string; // UUID
  email: string;
  display_name?: string;
  phone_number?: string;
  avatar_url?: string;
  role: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  _reports_count?: number;
  _matches_count?: number;
}

export interface Conversation {
  id: string; // UUID
  participant_one_id: string; // UUID
  participant_two_id: string; // UUID
  match_id?: string; // UUID
  created_at: string;
  updated_at: string;
  messages?: Message[];
}

export interface Message {
  id: string; // UUID
  conversation_id: string; // UUID
  sender_id: string; // UUID
  content: string;
  is_read: boolean;
  created_at: string;
  sender?: User;
}

export interface Notification {
  id: string; // UUID
  user_id: string; // UUID
  type: string;
  title: string;
  content?: string;
  reference_id?: string; // UUID
  is_read: boolean;
  created_at: string;
}

export interface AuditLogEntry {
  id: string; // UUID
  user_id?: string; // UUID
  action: string;
  resource_type: string;
  resource_id?: string; // UUID
  details?: string;
  created_at: string;
  user?: User;
}

export interface Category {
  id: string;
  name: string;
  icon?: string;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

export interface Color {
  id: string;
  name: string;
  hex_code?: string;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

export interface SystemHealth {
  status: string;
  service: string;
  version: string;
  environment: string;
  features: {
    metrics: boolean;
    rate_limit: boolean;
    redis_cache: boolean;
    notifications: boolean;
  };
  services: {
    nlp: string;
    vision: string;
  };
}
