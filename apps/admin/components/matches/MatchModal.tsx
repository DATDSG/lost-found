"use client";

import { Fragment } from "react";
import { Dialog, Transition } from "@headlessui/react";
import { XMarkIcon } from "@heroicons/react/24/outline";
import { format } from "date-fns";

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

interface MatchModalProps {
  match: Match | null;
  isOpen: boolean;
  onClose: () => void;
  onStatusUpdate: (matchId: string, status: string) => void;
}

export function MatchModal({
  match,
  isOpen,
  onClose,
  onStatusUpdate,
}: MatchModalProps) {
  if (!match) return null;

  const getStatusBadge = (status: string) => {
    const styles = {
      candidate: "bg-blue-100 text-blue-800",
      promoted: "bg-green-100 text-green-800",
      suppressed: "bg-gray-100 text-gray-800",
      dismissed: "bg-red-100 text-red-800",
    };
    return styles[status as keyof typeof styles] || "bg-gray-100 text-gray-800";
  };

  const getTypeBadge = (type: string) => {
    return type === "lost"
      ? "bg-red-100 text-red-800"
      : "bg-green-100 text-green-800";
  };

  const getScoreColor = (score: number) => {
    if (score >= 80) return "text-green-600";
    if (score >= 60) return "text-yellow-600";
    return "text-red-600";
  };

  const scoreComponents = [
    { name: "Text Similarity", score: match.score_text, color: "blue" },
    { name: "Image Similarity", score: match.score_image, color: "purple" },
    { name: "Location", score: match.score_geo, color: "green" },
    { name: "Time", score: match.score_time, color: "yellow" },
    { name: "Color", score: match.score_color, color: "pink" },
  ];

  return (
    <Transition appear show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={onClose}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black bg-opacity-25" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4 text-center">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-6xl transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all">
                <div className="flex items-center justify-between mb-6">
                  <Dialog.Title
                    as="h3"
                    className="text-lg font-medium leading-6 text-gray-900"
                  >
                    Match Details
                  </Dialog.Title>
                  <button
                    type="button"
                    className="text-gray-400 hover:text-gray-600"
                    onClick={onClose}
                    aria-label="Close modal"
                    title="Close modal"
                  >
                    <XMarkIcon className="h-6 w-6" />
                  </button>
                </div>

                <div className="space-y-6">
                  {/* Match Score */}
                  <div className="text-center">
                    <div
                      className={`text-4xl font-bold ${getScoreColor(
                        match.score_total * 100
                      )}`}
                    >
                      {Math.round(match.score_total * 100)}%
                    </div>
                    <div className="flex items-center justify-center space-x-3 mt-2">
                      <span
                        className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusBadge(
                          match.status
                        )}`}
                      >
                        {match.status}
                      </span>
                      <span className="text-sm text-gray-500">
                        Created {format(new Date(match.created_at), "PPP p")}
                      </span>
                    </div>
                  </div>

                  {/* Score Breakdown */}
                  <div>
                    <h4 className="text-sm font-medium text-gray-900 mb-3">
                      Score Breakdown
                    </h4>
                    <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-5">
                      {scoreComponents.map((component) => (
                        <div key={component.name} className="text-center">
                          <div
                            className={`text-lg font-semibold text-${component.color}-600`}
                          >
                            {Math.round(component.score * 100)}%
                          </div>
                          <div className="text-xs text-gray-500">
                            {component.name}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Reports Comparison */}
                  <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                    {/* Source Report */}
                    <div className="border rounded-lg p-4">
                      <div className="flex items-center justify-between mb-3">
                        <h4 className="text-sm font-medium text-gray-900">
                          Source Report
                        </h4>
                        <span
                          className={`px-2 py-1 rounded-full text-xs font-medium ${getTypeBadge(
                            match.source_report.type
                          )}`}
                        >
                          {match.source_report.type}
                        </span>
                      </div>

                      <h5 className="font-semibold text-gray-900 mb-2">
                        {match.source_report.title}
                      </h5>
                      <p className="text-sm text-gray-600 mb-3">
                        {match.source_report.description}
                      </p>

                      <div className="space-y-2 text-sm">
                        <div>
                          <span className="font-medium">Category:</span>{" "}
                          {match.source_report.category}
                        </div>
                        <div>
                          <span className="font-medium">Location:</span>{" "}
                          {match.source_report.location_city}
                        </div>
                        <div>
                          <span className="font-medium">Occurred:</span>{" "}
                          {format(
                            new Date(match.source_report.occurred_at),
                            "PPP p"
                          )}
                        </div>
                        <div>
                          <span className="font-medium">Owner:</span>{" "}
                          {match.source_report.owner.display_name ||
                            match.source_report.owner.email}
                        </div>
                      </div>

                      {match.source_report.media &&
                        match.source_report.media.length > 0 && (
                          <div className="mt-3">
                            <div className="grid grid-cols-2 gap-2">
                              {match.source_report.media
                                .slice(0, 2)
                                .map((media) => (
                                  <img
                                    key={media.id}
                                    src={media.url}
                                    alt={media.filename}
                                    className="w-full h-20 object-cover rounded"
                                  />
                                ))}
                            </div>
                          </div>
                        )}
                    </div>

                    {/* Candidate Report */}
                    <div className="border rounded-lg p-4">
                      <div className="flex items-center justify-between mb-3">
                        <h4 className="text-sm font-medium text-gray-900">
                          Candidate Report
                        </h4>
                        <span
                          className={`px-2 py-1 rounded-full text-xs font-medium ${getTypeBadge(
                            match.candidate_report.type
                          )}`}
                        >
                          {match.candidate_report.type}
                        </span>
                      </div>

                      <h5 className="font-semibold text-gray-900 mb-2">
                        {match.candidate_report.title}
                      </h5>
                      <p className="text-sm text-gray-600 mb-3">
                        {match.candidate_report.description}
                      </p>

                      <div className="space-y-2 text-sm">
                        <div>
                          <span className="font-medium">Category:</span>{" "}
                          {match.candidate_report.category}
                        </div>
                        <div>
                          <span className="font-medium">Location:</span>{" "}
                          {match.candidate_report.location_city}
                        </div>
                        <div>
                          <span className="font-medium">Occurred:</span>{" "}
                          {format(
                            new Date(match.candidate_report.occurred_at),
                            "PPP p"
                          )}
                        </div>
                        <div>
                          <span className="font-medium">Owner:</span>{" "}
                          {match.candidate_report.owner.display_name ||
                            match.candidate_report.owner.email}
                        </div>
                      </div>

                      {match.candidate_report.media &&
                        match.candidate_report.media.length > 0 && (
                          <div className="mt-3">
                            <div className="grid grid-cols-2 gap-2">
                              {match.candidate_report.media
                                .slice(0, 2)
                                .map((media) => (
                                  <img
                                    key={media.id}
                                    src={media.url}
                                    alt={media.filename}
                                    className="w-full h-20 object-cover rounded"
                                  />
                                ))}
                            </div>
                          </div>
                        )}
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center justify-between pt-6 border-t border-gray-200">
                    <div className="flex space-x-3">
                      {match.status === "candidate" && (
                        <button
                          onClick={() => {
                            onStatusUpdate(match.id, "promoted");
                            onClose();
                          }}
                          className="btn btn-primary"
                        >
                          Promote Match
                        </button>
                      )}
                      {match.status === "promoted" && (
                        <button
                          onClick={() => {
                            onStatusUpdate(match.id, "suppressed");
                            onClose();
                          }}
                          className="btn btn-secondary"
                        >
                          Suppress Match
                        </button>
                      )}
                      <button
                        onClick={() => {
                          onStatusUpdate(match.id, "dismissed");
                          onClose();
                        }}
                        className="btn btn-danger"
                      >
                        Dismiss Match
                      </button>
                    </div>
                    <button onClick={onClose} className="btn btn-secondary">
                      Close
                    </button>
                  </div>
                </div>
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  );
}
