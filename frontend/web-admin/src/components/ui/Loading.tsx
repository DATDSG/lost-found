export function Loading({ message = "Loading..." }: { message?: string }) {
  return (
    <div className="flex flex-col items-center justify-center p-8 space-y-4">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" />
      <p className="text-sm text-gray-600">{message}</p>
    </div>
  );
}

export function LoadingOverlay({ children }: { children?: React.ReactNode }) {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-8">{children || <Loading />}</div>
    </div>
  );
}
