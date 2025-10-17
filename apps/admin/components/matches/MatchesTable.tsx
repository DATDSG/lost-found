"use client";

import { useState } from "react";
import { formatDistanceToNow } from "date-fns";
import {
  EyeIcon,
  CheckIcon,
  XMarkIcon,
  ArrowUpIcon,
  ArrowDownIcon,
  LinkIcon,
  PhotoIcon,
  UserIcon,
  MapPinIcon,
  CalendarIcon,
  TagIcon,
} from "@heroicons/react/24/outline";
import { useMutation, useQueryClient } from "react-query";
import apiClient from "@/lib/api";
import { toast } from "react-toastify";

interface Match {
  id: string;
  source_report_id: string;
  candidate_report_id: string;
  status: "candidate" | "promoted" | "suppressed" | "dismissed";
  score_total: number;
  score_text: number;
  score_image: number;
  score_geo: number;
  score_time: number;
  score_color: number;
  created_at: string;
  reviewed_by: string | null;
  reviewed_at: string | null;
  source_report: {
    id: string;
    title: string;
    description: string;
    type: "lost" | "found";
    status: string;
    category: string;
    colors: string[];
    location_city: string;
    location_address: string;
    occurred_at: string;
    created_at: string;
    owner: {
      id: string;
      email: string;
      display_name: string;
    };
    media: Array<{
      id: string;
      url: string;
      filename: string;
      media_type: string;
    }>;
  };
  candidate_report: {
    id: string;
    title: string;
    description: string;
    type: "lost" | "found";
    status: string;
    category: string;
    colors: string[];
    location_city: string;
    location_address: string;
    occurred_at: string;
    created_at: string;
    owner: {
      id: string;
      email: string;
      display_name: string;
    };
    media: Array<{
      id: string;
      url: string;
      filename: string;
      media_type: string;
    }>;
  };
}

interface MatchesTableProps {
  matches: Match[];
  isLoading: boolean;
  selectedMatches: string[];
  onSelectionChange: (selected: string[]) => void;
  onStatusUpdate: (matchId: string, status: string) => void;
  onViewMatch: (match: Match) => void;
  pagination: {
    page: number;
    total: number;
    pages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}

interface MatchDetailModalProps {
  match: Match | null;
  isOpen: boolean;
  onClose: () => void;
  onStatusUpdate: (matchId: string, status: string) => void;
}

function MatchDetailModal({
  match,
  isOpen,
  onClose,
  onStatusUpdate,
}: MatchDetailModalProps) {
  const [isSuppressing, setIsSuppressing] = useState(false);
  const [suppressReason, setSuppressReason] = useState("");
  const queryClient = useQueryClient();

  const promoteMutation = useMutation(apiClient.promoteMatch, {
    onSuccess: () => {
      toast.success("Match promoted successfully!");
      queryClient.invalidateQueries("matches");
      onStatusUpdate(match!.id, "promoted");
      onClose();
    },
    onError: (error: any) => {
      toast.error(`Failed to promote match: ${error.message}`);
    },
  });

  const suppressMutation = useMutation(
    ({ matchId, reason }: { matchId: string; reason: string }) =>
      apiClient.suppressMatch(matchId, reason),
    {
      onSuccess: () => {
        toast.success("Match suppressed successfully!");
        queryClient.invalidateQueries("matches");
        onStatusUpdate(match!.id, "suppressed");
        onClose();
      },
      onError: (error: any) => {
        toast.error(`Failed to suppress match: ${error.message}`);
      },
    }
  );

  const handlePromote = () => {
    if (match) {
      promoteMutation.mutate(match.id);
    }
  };

  const handleSuppress = () => {
    if (match && suppressReason.trim()) {
      suppressMutation.mutate({ matchId: match.id, reason: suppressReason });
    }
  };

  if (!isOpen || !match) return null;

  const getScoreColor = (score: number) => {
    if (score >= 0.8) return "text-green-600";
    if (score >= 0.6) return "text-yellow-600";
    return "text-red-600";
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg max-w-6xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          {/* Header */}
          <div className="flex justify-between items-start mb-6">
            <div>
              <h2 className="text-2xl font-bold text-gray-900">
                Match Details
              </h2>
              <div className="flex items-center space-x-4 mt-2">
                <span
                  className={`px-2 py-1 rounded-full text-xs font-medium ${
                    match.status === "promoted"
                      ? "bg-green-100 text-green-800"
                      : match.status === "candidate"
                      ? "bg-yellow-100 text-yellow-800"
                      : match.status === "suppressed"
                      ? "bg-red-100 text-red-800"
                      : "bg-gray-100 text-gray-800"
                  }`}
                >
                  {match.status.toUpperCase()}
                </span>
                <span className="text-sm text-gray-500">
                  {match.created_at
                    ? formatDistanceToNow(new Date(match.created_at), {
                        addSuffix: true,
                      })
                    : "Unknown"}
                </span>
                <span className="text-lg font-bold text-gray-900">
                  Score: {(match.score_total * 100).toFixed(1)}%
                </span>
              </div>
            </div>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
              aria-label="Close modal"
              title="Close modal"
            >
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>

          {/* Score Breakdown */}
          <div className="mb-6 p-4 bg-gray-50 rounded-lg">
            <h3 className="text-lg font-medium text-gray-900 mb-3">
              Match Score Breakdown
            </h3>
            <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
              <div className="text-center">
                <div
                  className={`text-2xl font-bold ${getScoreColor(
                    match.score_text
                  )}`}
                >
                  {(match.score_text * 100).toFixed(0)}%
                </div>
                <div className="text-sm text-gray-600">Text</div>
              </div>
              <div className="text-center">
                <div
                  className={`text-2xl font-bold ${getScoreColor(
                    match.score_image
                  )}`}
                >
                  {(match.score_image * 100).toFixed(0)}%
                </div>
                <div className="text-sm text-gray-600">Image</div>
              </div>
              <div className="text-center">
                <div
                  className={`text-2xl font-bold ${getScoreColor(
                    match.score_geo
                  )}`}
                >
                  {(match.score_geo * 100).toFixed(0)}%
                </div>
                <div className="text-sm text-gray-600">Location</div>
              </div>
              <div className="text-center">
                <div
                  className={`text-2xl font-bold ${getScoreColor(
                    match.score_time
                  )}`}
                >
                  {(match.score_time * 100).toFixed(0)}%
                </div>
                <div className="text-sm text-gray-600">Time</div>
              </div>
              <div className="text-center">
                <div
                  className={`text-2xl font-bold ${getScoreColor(
                    match.score_color
                  )}`}
                >
                  {(match.score_color * 100).toFixed(0)}%
                </div>
                <div className="text-sm text-gray-600">Color</div>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Source Report */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-gray-900 flex items-center">
                <LinkIcon className="h-5 w-5 mr-2" />
                Source Report
              </h3>
              <div className="border border-gray-200 rounded-lg p-4">
                <div className="flex items-start space-x-3 mb-3">
                  {match.source_report.media &&
                  match.source_report.media.length > 0 ? (
                    <img
                      className="h-16 w-16 rounded-lg object-cover"
                      src={match.source_report.media[0].url}
                      alt={match.source_report.title}
                    />
                  ) : (
                    <div className="h-16 w-16 rounded-lg bg-gray-200 flex items-center justify-center">
                      <TagIcon className="h-6 w-6 text-gray-400" />
                    </div>
                  )}
                  <div className="flex-1">
                    <h4 className="font-medium text-gray-900">
                      {match.source_report.title}
                    </h4>
                    <p className="text-sm text-gray-600">
                      {match.source_report.category}
                    </p>
                    <div className="flex items-center space-x-2 mt-1">
                      <span
                        className={`px-2 py-1 rounded-full text-xs font-medium ${
                          match.source_report.type === "lost"
                            ? "bg-blue-100 text-blue-800"
                            : "bg-purple-100 text-purple-800"
                        }`}
                      >
                        {match.source_report.type}
                      </span>
                      <span
                        className={`px-2 py-1 rounded-full text-xs font-medium ${
                          match.source_report.status === "approved"
                            ? "bg-green-100 text-green-800"
                            : "bg-yellow-100 text-yellow-800"
                        }`}
                      >
                        {match.source_report.status}
                      </span>
                    </div>
                  </div>
                </div>
                <p className="text-sm text-gray-700 mb-3">
                  {match.source_report.description}
                </p>
                <div className="space-y-2 text-sm text-gray-600">
                  <div className="flex items-center">
                    <MapPinIcon className="h-4 w-4 mr-2" />
                    {match.source_report.location_city},{" "}
                    {match.source_report.location_address}
                  </div>
                  <div className="flex items-center">
                    <CalendarIcon className="h-4 w-4 mr-2" />
                    {match.source_report.occurred_at
                      ? new Date(
                          match.source_report.occurred_at
                        ).toLocaleDateString()
                      : "Not specified"}
                  </div>
                  <div className="flex items-center">
                    <UserIcon className="h-4 w-4 mr-2" />
                    {match.source_report.owner.display_name || "No name"} (
                    {match.source_report.owner.email})
                  </div>
                </div>
                {match.source_report.colors &&
                  match.source_report.colors.length > 0 && (
                    <div className="mt-3">
                      <div className="flex flex-wrap gap-1">
                        {match.source_report.colors.map((color, index) => (
                          <span
                            key={index}
                            className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs"
                          >
                            {color}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
              </div>
            </div>

            {/* Candidate Report */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-gray-900 flex items-center">
                <LinkIcon className="h-5 w-5 mr-2" />
                Candidate Report
              </h3>
              <div className="border border-gray-200 rounded-lg p-4">
                <div className="flex items-start space-x-3 mb-3">
                  {match.candidate_report.media &&
                  match.candidate_report.media.length > 0 ? (
                    <img
                      className="h-16 w-16 rounded-lg object-cover"
                      src={match.candidate_report.media[0].url}
                      alt={match.candidate_report.title}
                    />
                  ) : (
                    <div className="h-16 w-16 rounded-lg bg-gray-200 flex items-center justify-center">
                      <TagIcon className="h-6 w-6 text-gray-400" />
                    </div>
                  )}
                  <div className="flex-1">
                    <h4 className="font-medium text-gray-900">
                      {match.candidate_report.title}
                    </h4>
                    <p className="text-sm text-gray-600">
                      {match.candidate_report.category}
                    </p>
                    <div className="flex items-center space-x-2 mt-1">
                      <span
                        className={`px-2 py-1 rounded-full text-xs font-medium ${
                          match.candidate_report.type === "lost"
                            ? "bg-blue-100 text-blue-800"
                            : "bg-purple-100 text-purple-800"
                        }`}
                      >
                        {match.candidate_report.type}
                      </span>
                      <span
                        className={`px-2 py-1 rounded-full text-xs font-medium ${
                          match.candidate_report.status === "approved"
                            ? "bg-green-100 text-green-800"
                            : "bg-yellow-100 text-yellow-800"
                        }`}
                      >
                        {match.candidate_report.status}
                      </span>
                    </div>
                  </div>
                </div>
                <p className="text-sm text-gray-700 mb-3">
                  {match.candidate_report.description}
                </p>
                <div className="space-y-2 text-sm text-gray-600">
                  <div className="flex items-center">
                    <MapPinIcon className="h-4 w-4 mr-2" />
                    {match.candidate_report.location_city},{" "}
                    {match.candidate_report.location_address}
                  </div>
                  <div className="flex items-center">
                    <CalendarIcon className="h-4 w-4 mr-2" />
                    {match.candidate_report.occurred_at
                      ? new Date(
                          match.candidate_report.occurred_at
                        ).toLocaleDateString()
                      : "Not specified"}
                  </div>
                  <div className="flex items-center">
                    <UserIcon className="h-4 w-4 mr-2" />
                    {match.candidate_report.owner.display_name || "No name"} (
                    {match.candidate_report.owner.email})
                  </div>
                </div>
                {match.candidate_report.colors &&
                  match.candidate_report.colors.length > 0 && (
                    <div className="mt-3">
                      <div className="flex flex-wrap gap-1">
                        {match.candidate_report.colors.map((color, index) => (
                          <span
                            key={index}
                            className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs"
                          >
                            {color}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="mt-8 pt-6 border-t border-gray-200">
            <div className="flex justify-between items-center">
              <div className="flex space-x-3">
                {match.status === "candidate" && (
                  <>
                    <button
                      onClick={handlePromote}
                      disabled={promoteMutation.isLoading}
                      className="flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
                    >
                      <ArrowUpIcon className="h-4 w-4 mr-2" />
                      {promoteMutation.isLoading ? "Promoting..." : "Promote"}
                    </button>
                    <button
                      onClick={() => setIsSuppressing(true)}
                      className="flex items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
                    >
                      <ArrowDownIcon className="h-4 w-4 mr-2" />
                      Suppress
                    </button>
                  </>
                )}
                {match.status === "promoted" && (
                  <button
                    onClick={() => onStatusUpdate(match.id, "suppressed")}
                    className="flex items-center px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700"
                  >
                    <ArrowDownIcon className="h-4 w-4 mr-2" />
                    Suppress
                  </button>
                )}
                {match.status === "suppressed" && (
                  <button
                    onClick={() => onStatusUpdate(match.id, "promoted")}
                    className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                  >
                    <ArrowUpIcon className="h-4 w-4 mr-2" />
                    Promote
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Suppress Modal */}
      {isSuppressing && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-60">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              Suppress Match
            </h3>
            <p className="text-sm text-gray-600 mb-4">
              Please provide a reason for suppressing this match:
            </p>
            <textarea
              value={suppressReason}
              onChange={(e) => setSuppressReason(e.target.value)}
              placeholder="Enter suppression reason..."
              className="w-full p-3 border border-gray-300 rounded-lg mb-4"
              rows={3}
            />
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => {
                  setIsSuppressing(false);
                  setSuppressReason("");
                }}
                className="px-4 py-2 text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
              <button
                onClick={handleSuppress}
                disabled={!suppressReason.trim() || suppressMutation.isLoading}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
              >
                {suppressMutation.isLoading
                  ? "Suppressing..."
                  : "Suppress Match"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function MatchesTable({
  matches,
  isLoading,
  selectedMatches,
  onSelectionChange,
  onStatusUpdate,
  onViewMatch,
  pagination,
}: MatchesTableProps) {
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [selectedMatch, setSelectedMatch] = useState<Match | null>(null);

  const handleViewMatch = (match: Match) => {
    setSelectedMatch(match);
    setShowDetailModal(true);
    onViewMatch(match);
  };

  const handleCloseModal = () => {
    setShowDetailModal(false);
    setSelectedMatch(null);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "promoted":
        return "bg-green-100 text-green-800";
      case "candidate":
        return "bg-yellow-100 text-yellow-800";
      case "suppressed":
        return "bg-red-100 text-red-800";
      case "dismissed":
        return "bg-gray-100 text-gray-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  const getScoreColor = (score: number) => {
    if (score >= 0.8) return "text-green-600";
    if (score >= 0.6) return "text-yellow-600";
    return "text-red-600";
  };

  if (isLoading) {
    return (
      <div className="bg-white shadow rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <div className="animate-pulse">
            <div className="h-4 bg-gray-200 rounded w-1/4 mb-4"></div>
            <div className="space-y-3">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="h-16 bg-gray-200 rounded"></div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <>
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="px-4 py-5 sm:p-6">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    <input
                      type="checkbox"
                      checked={
                        selectedMatches.length === matches.length &&
                        matches.length > 0
                      }
                      onChange={(e) => {
                        if (e.target.checked) {
                          onSelectionChange(matches.map((m) => m.id));
                        } else {
                          onSelectionChange([]);
                        }
                      }}
                      className="rounded border-gray-300"
                      aria-label="Select all matches"
                      title="Select all matches"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Match Score
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Source Report
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Candidate Report
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Created
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {matches.map((match) => (
                  <tr key={match.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <input
                        type="checkbox"
                        checked={selectedMatches.includes(match.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            onSelectionChange([...selectedMatches, match.id]);
                          } else {
                            onSelectionChange(
                              selectedMatches.filter((id) => id !== match.id)
                            );
                          }
                        }}
                        className="rounded border-gray-300"
                        aria-label={`Select match ${match.id}`}
                        title={`Select match ${match.id}`}
                      />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-center">
                        <div
                          className={`text-lg font-bold ${getScoreColor(
                            match.score_total
                          )}`}
                        >
                          {(match.score_total * 100).toFixed(1)}%
                        </div>
                        <div className="text-xs text-gray-500">
                          T:{(match.score_text * 100).toFixed(0)}% I:
                          {(match.score_image * 100).toFixed(0)}% G:
                          {(match.score_geo * 100).toFixed(0)}%
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="flex-shrink-0 h-10 w-10">
                          {match.source_report.media &&
                          match.source_report.media.length > 0 ? (
                            <img
                              className="h-10 w-10 rounded-lg object-cover"
                              src={match.source_report.media[0].url}
                              alt={match.source_report.title}
                            />
                          ) : (
                            <div className="h-10 w-10 rounded-lg bg-gray-200 flex items-center justify-center">
                              <TagIcon className="h-5 w-5 text-gray-400" />
                            </div>
                          )}
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900 truncate max-w-xs">
                            {match.source_report.title}
                          </div>
                          <div className="text-sm text-gray-500 truncate max-w-xs">
                            {match.source_report.owner.display_name ||
                              "No name"}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="flex-shrink-0 h-10 w-10">
                          {match.candidate_report.media &&
                          match.candidate_report.media.length > 0 ? (
                            <img
                              className="h-10 w-10 rounded-lg object-cover"
                              src={match.candidate_report.media[0].url}
                              alt={match.candidate_report.title}
                            />
                          ) : (
                            <div className="h-10 w-10 rounded-lg bg-gray-200 flex items-center justify-center">
                              <TagIcon className="h-5 w-5 text-gray-400" />
                            </div>
                          )}
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900 truncate max-w-xs">
                            {match.candidate_report.title}
                          </div>
                          <div className="text-sm text-gray-500 truncate max-w-xs">
                            {match.candidate_report.owner.display_name ||
                              "No name"}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(
                          match.status
                        )}`}
                      >
                        {match.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {match.created_at
                        ? formatDistanceToNow(new Date(match.created_at), {
                            addSuffix: true,
                          })
                        : "Unknown"}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex space-x-2">
                        <button
                          onClick={() => handleViewMatch(match)}
                          className="text-indigo-600 hover:text-indigo-900"
                          title="View Details"
                          aria-label="View match details"
                        >
                          <EyeIcon className="h-4 w-4" />
                        </button>
                        {match.status === "candidate" && (
                          <>
                            <button
                              onClick={() =>
                                onStatusUpdate(match.id, "promoted")
                              }
                              className="text-green-600 hover:text-green-900"
                              title="Promote"
                            >
                              <ArrowUpIcon className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() =>
                                onStatusUpdate(match.id, "suppressed")
                              }
                              className="text-red-600 hover:text-red-900"
                              title="Suppress"
                            >
                              <ArrowDownIcon className="h-4 w-4" />
                            </button>
                          </>
                        )}
                        {match.status === "promoted" && (
                          <button
                            onClick={() =>
                              onStatusUpdate(match.id, "suppressed")
                            }
                            className="text-yellow-600 hover:text-yellow-900"
                            title="Suppress"
                          >
                            <ArrowDownIcon className="h-4 w-4" />
                          </button>
                        )}
                        {match.status === "suppressed" && (
                          <button
                            onClick={() => onStatusUpdate(match.id, "promoted")}
                            className="text-blue-600 hover:text-blue-900"
                            title="Promote"
                          >
                            <ArrowUpIcon className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
            <div className="flex-1 flex justify-between sm:hidden">
              <button
                onClick={() => {
                  /* Handle prev page */
                }}
                disabled={!pagination.hasPrev}
                className="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
              >
                Previous
              </button>
              <button
                onClick={() => {
                  /* Handle next page */
                }}
                disabled={!pagination.hasNext}
                className="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
              >
                Next
              </button>
            </div>
            <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
              <div>
                <p className="text-sm text-gray-700">
                  Showing page{" "}
                  <span className="font-medium">{pagination.page}</span> of{" "}
                  <span className="font-medium">{pagination.pages}</span> (
                  {pagination.total} total)
                </p>
              </div>
              <div>
                <nav
                  className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
                  aria-label="Pagination"
                >
                  <button
                    onClick={() => {
                      /* Handle prev page */
                    }}
                    disabled={!pagination.hasPrev}
                    className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => {
                      /* Handle next page */
                    }}
                    disabled={!pagination.hasNext}
                    className="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                  >
                    Next
                  </button>
                </nav>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Match Detail Modal */}
      <MatchDetailModal
        match={selectedMatch}
        isOpen={showDetailModal}
        onClose={handleCloseModal}
        onStatusUpdate={onStatusUpdate}
      />
    </>
  );
}
