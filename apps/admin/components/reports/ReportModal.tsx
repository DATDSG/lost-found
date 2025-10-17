"use client";

import { Fragment } from "react";
import { Dialog, Transition } from "@headlessui/react";
import { XMarkIcon } from "@heroicons/react/24/outline";
import { format } from "date-fns";

interface Report {
  id: string;
  title: string;
  description: string;
  type: "lost" | "found";
  status: "pending" | "approved" | "hidden" | "removed" | "rejected";
  category: string;
  location_city: string;
  location_address: string;
  occurred_at: string;
  created_at: string;
  updated_at: string;
  reward_offered: boolean;
  is_resolved: boolean;
  owner: {
    id: string;
    email: string;
    display_name: string;
    phone_number: string;
  };
  media: Array<{
    id: string;
    url: string;
    filename: string;
    media_type: string;
  }>;
}

interface ReportModalProps {
  report: Report | null;
  isOpen: boolean;
  onClose: () => void;
  onStatusUpdate: (reportId: string, status: string) => void;
}

export function ReportModal({
  report,
  isOpen,
  onClose,
  onStatusUpdate,
}: ReportModalProps) {
  if (!report) return null;

  const getStatusBadge = (status: string) => {
    const styles = {
      pending: "bg-yellow-100 text-yellow-800",
      approved: "bg-green-100 text-green-800",
      hidden: "bg-gray-100 text-gray-800",
      removed: "bg-red-100 text-red-800",
    };
    return styles[status as keyof typeof styles] || "bg-gray-100 text-gray-800";
  };

  const getTypeBadge = (type: string) => {
    return type === "lost"
      ? "bg-red-100 text-red-800"
      : "bg-green-100 text-green-800";
  };

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
              <Dialog.Panel className="w-full max-w-4xl transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all">
                <div className="flex items-center justify-between mb-6">
                  <Dialog.Title
                    as="h3"
                    className="text-lg font-medium leading-6 text-gray-900"
                  >
                    Report Details
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
                  {/* Header Info */}
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h2 className="text-xl font-semibold text-gray-900 mb-2">
                        {report.title}
                      </h2>
                      <div className="flex items-center space-x-3">
                        <span
                          className={`px-3 py-1 rounded-full text-sm font-medium ${getTypeBadge(
                            report.type
                          )}`}
                        >
                          {report.type}
                        </span>
                        <span
                          className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusBadge(
                            report.status
                          )}`}
                        >
                          {report.status}
                        </span>
                        {report.reward_offered && (
                          <span className="px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-800">
                            Reward Offered
                          </span>
                        )}
                        {report.is_resolved && (
                          <span className="px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
                            Resolved
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Images */}
                  {report.media && report.media.length > 0 && (
                    <div>
                      <h4 className="text-sm font-medium text-gray-900 mb-3">
                        Images
                      </h4>
                      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
                        {report.media.map((media) => (
                          <div key={media.id} className="relative">
                            <img
                              src={media.url}
                              alt={media.filename}
                              className="w-full h-32 object-cover rounded-lg"
                            />
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Details Grid */}
                  <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                    <div>
                      <h4 className="text-sm font-medium text-gray-900 mb-3">
                        Report Information
                      </h4>
                      <dl className="space-y-2">
                        <div>
                          <dt className="text-sm text-gray-500">Category</dt>
                          <dd className="text-sm text-gray-900">
                            {report.category}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-sm text-gray-500">Location</dt>
                          <dd className="text-sm text-gray-900">
                            {report.location_city}
                            {report.location_address && (
                              <div className="text-xs text-gray-500 mt-1">
                                {report.location_address}
                              </div>
                            )}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-sm text-gray-500">Occurred At</dt>
                          <dd className="text-sm text-gray-900">
                            {format(new Date(report.occurred_at), "PPP p")}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-sm text-gray-500">Created</dt>
                          <dd className="text-sm text-gray-900">
                            {format(new Date(report.created_at), "PPP p")}
                          </dd>
                        </div>
                      </dl>
                    </div>

                    <div>
                      <h4 className="text-sm font-medium text-gray-900 mb-3">
                        Owner Information
                      </h4>
                      <dl className="space-y-2">
                        <div>
                          <dt className="text-sm text-gray-500">Name</dt>
                          <dd className="text-sm text-gray-900">
                            {report.owner.display_name || "Not provided"}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-sm text-gray-500">Email</dt>
                          <dd className="text-sm text-gray-900">
                            {report.owner.email}
                          </dd>
                        </div>
                        {report.owner.phone_number && (
                          <div>
                            <dt className="text-sm text-gray-500">Phone</dt>
                            <dd className="text-sm text-gray-900">
                              {report.owner.phone_number}
                            </dd>
                          </div>
                        )}
                      </dl>
                    </div>
                  </div>

                  {/* Description */}
                  <div>
                    <h4 className="text-sm font-medium text-gray-900 mb-3">
                      Description
                    </h4>
                    <p className="text-sm text-gray-700 whitespace-pre-wrap">
                      {report.description}
                    </p>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center justify-between pt-6 border-t border-gray-200">
                    <div className="flex space-x-3">
                      {report.status === "pending" && (
                        <button
                          onClick={() => {
                            onStatusUpdate(report.id, "approved");
                            onClose();
                          }}
                          className="btn btn-primary"
                        >
                          Approve Report
                        </button>
                      )}
                      {report.status === "approved" && (
                        <button
                          onClick={() => {
                            onStatusUpdate(report.id, "hidden");
                            onClose();
                          }}
                          className="btn btn-secondary"
                        >
                          Hide Report
                        </button>
                      )}
                      <button
                        onClick={() => {
                          onStatusUpdate(report.id, "removed");
                          onClose();
                        }}
                        className="btn btn-danger"
                      >
                        Remove Report
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
