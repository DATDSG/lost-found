// Base types
export interface PaginatedResponse<T> {
    items: T[];
    total: number;
    page: number;
    per_page: number;
    pages: number;
    total_pages: number;
}

// User types
export interface User {
    id: string;
    email: string;
    first_name: string;
    last_name: string;
    display_name?: string;
    role: 'admin' | 'moderator' | 'user';
    status: 'active' | 'inactive' | 'suspended';
    is_active?: boolean;
    is_verified?: boolean;
    created_at: string;
    updated_at: string;
    last_login_at?: string;
    last_login?: string;
    reports_count: number;
    matches_count: number;
}

export interface UserFilters {
    search?: string;
    role?: string;
    status?: string;
    created_from?: string;
    created_to?: string;
    page?: number;
    limit?: number;
}

// Report types
export interface Report {
    id: string;
    title: string;
    description: string;
    type: 'lost' | 'found';
    category: string;
    location_city: string;
    location_address?: string;
    latitude?: number;
    longitude?: number;
    reward_offered: boolean;
    reward_amount?: number;
    status: 'pending' | 'approved' | 'rejected' | 'archived';
    created_at: string;
    updated_at: string;
    owner_id: string;
    owner_email: string;
    owner?: User;
    images: string[];
    tags: string[];
    fraud_status?: 'clean' | 'flagged' | 'reviewed';
    fraud_score?: number;
}

export interface ReportFilters {
    search?: string;
    type?: string;
    status?: string;
    category?: string;
    date_from?: string;
    date_to?: string;
    page?: number;
    limit?: number;
}

// Match types
export interface Match {
    id: string;
    source_report_id: string;
    candidate_report_id: string;
    overall_score: number;
    text_score?: number;
    image_score?: number;
    geo_score?: number;
    time_score?: number;
    color_score?: number;
    status: 'candidate' | 'promoted' | 'suppressed' | 'dismissed';
    created_at: string;
    source_report: Report;
    candidate_report: Report;
    reviewed_by?: string;
    reviewed_at?: string;
}

export interface MatchFilters {
    status?: string;
    min_score?: number;
    max_score?: number;
    date_from?: string;
    date_to?: string;
}

// Fraud Detection types
export interface FraudDetectionResult {
    id: string;
    report_id: string;
    fraud_score: number;
    risk_level: 'low' | 'medium' | 'high' | 'critical';
    is_reviewed: boolean;
    is_confirmed_fraud: boolean;
    confidence?: number;
    flags?: string[];
    detected_at?: string;
    created_at: string;
    updated_at: string;
    report: Report;
    reviewed_by?: string;
    reviewed_at?: string;
    admin_notes?: string;
}

export interface FraudFilters {
    risk_level?: string;
    is_reviewed?: boolean;
    date_from?: string;
    date_to?: string;
}

// Audit Log types
export interface AuditLog {
    id: string;
    action: string;
    resource_type?: string;
    resource?: string; // Keep for backward compatibility
    resource_id?: string;
    user_id?: string; // New field from API
    actor_id?: string; // Keep for backward compatibility
    actor_email: string;
    reason?: string; // Keep for backward compatibility
    details?: string; // New field from API
    created_at: string;
}

export interface AuditFilters {
    search?: string;
    action?: string;
    resource?: string;
    actor_email?: string;
    date_from?: string;
    date_to?: string;
}

// Dashboard types
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
    pending_matches: number;
    fraud_detections: number;
    pending_fraud_reviews: number;
    recent_activity: Array<{
        description: string;
        timestamp: string;
        type: string;
        action: string;
        details: string;
    }>;
    generated_at?: string;
}

// API Response types
export interface ApiResponse<T> {
    data: T;
    message?: string;
    success: boolean;
}

export interface ErrorResponse {
    message: string;
    details?: string;
    code?: string;
}