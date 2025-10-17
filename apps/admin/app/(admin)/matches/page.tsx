"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "react-query";
import apiClient from "@/lib/api";
import toast from "react-hot-toast";
import MatchesTable from "@/components/matches/MatchesTable";
import { MatchFilters } from "@/components/matches/MatchFilters";
import { MatchModal } from "@/components/matches/MatchModal";

interface Match {
  id: string;
  score_total: number;
  score_text: number;
  score_image: number;
  score_geo: number;
  score_time: number;
  score_color: number;
  status: "candidate" | "promoted" | "suppressed" | "dismissed";
  created_at: string;
  source_report: {
    id: string;
    title: string;
    description: string;
    type: "lost" | "found";
    category: string;
    location_city: string;
    location_address: string;
    occurred_at: string;
    media: Array<{
      id: string;
      url: string;
      filename: string;
      media_type: string;
    }>;
    owner: {
      id: string;
      email: string;
      display_name: string;
    };
  };
  candidate_report: {
    id: string;
    title: string;
    description: string;
    type: "lost" | "found";
    category: string;
    location_city: string;
    location_address: string;
    occurred_at: string;
    media: Array<{
      id: string;
      url: string;
      filename: string;
      media_type: string;
    }>;
    owner: {
      id: string;
      email: string;
      display_name: string;
    };
  };
}

interface Filters {
  search: string;
  status: string;
  min_score: string;
  max_score: string;
  type: string;
}

export default function MatchesPage() {
  const [filters, setFilters] = useState<Filters>({
    search: "",
    status: "",
    min_score: "",
    max_score: "",
    type: "",
  });
  const [selectedMatch, setSelectedMatch] = useState<Match | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [page, setPage] = useState(1);
  const queryClient = useQueryClient();

  const { data: matchesData, isLoading } = useQuery(
    ["matches", page, filters],
    async () => {
      const params = {
        skip: ((page - 1) * 20).toString(),
        limit: "20",
        ...Object.fromEntries(Object.entries(filters).filter(([_, v]) => v)),
      };
      return await apiClient.getMatches(params);
    }
  );

  const updateStatusMutation = useMutation(
    async ({ matchId, status }: { matchId: string; status: string }) => {
      return await apiClient.updateMatchStatus(matchId, status);
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries(["matches"]);
        toast.success("Match status updated");
      },
      onError: () => {
        toast.error("Failed to update match status");
      },
    }
  );

  const handleStatusUpdate = (matchId: string, status: string) => {
    updateStatusMutation.mutate({ matchId, status });
  };

  const handleViewMatch = (match: Match) => {
    setSelectedMatch(match);
    setIsModalOpen(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Matches</h1>
          <p className="mt-1 text-sm text-gray-500">
            Manage potential matches between lost and found items
          </p>
        </div>
      </div>

      <MatchFilters filters={filters} onFiltersChange={setFilters} />

      <MatchesTable
        matches={matchesData?.items || []}
        isLoading={isLoading}
        selectedMatches={[]}
        onSelectionChange={() => {}}
        onStatusUpdate={handleStatusUpdate}
        onViewMatch={handleViewMatch}
        pagination={{
          page,
          total: matchesData?.total || 0,
          pages: Math.ceil((matchesData?.total || 0) / 20),
          hasNext: page < Math.ceil((matchesData?.total || 0) / 20),
          hasPrev: page > 1,
        }}
      />

      <MatchModal
        match={selectedMatch}
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedMatch(null);
        }}
        onStatusUpdate={handleStatusUpdate}
      />
    </div>
  );
}
