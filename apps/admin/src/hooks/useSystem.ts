import {
  useQuery,
  useMutation,
  useQueryClient,
  keepPreviousData,
} from "@tanstack/react-query";
import { systemService, type AuditLogFilters } from "@/services";
import { useSnackbar } from "notistack";

export const useSystemHealth = () => {
  return useQuery({
    queryKey: ["systemHealth"],
    queryFn: systemService.getHealth,
    refetchInterval: 10000, // Refetch every 10 seconds
  });
};

export const useSystemMetrics = () => {
  return useQuery({
    queryKey: ["systemMetrics"],
    queryFn: systemService.getMetrics,
    refetchInterval: 15000, // Refetch every 15 seconds
  });
};

export const useAuditLogs = (filters: AuditLogFilters = {}) => {
  return useQuery({
    queryKey: ["auditLogs", filters],
    queryFn: () => systemService.getAuditLogs(filters),
    placeholderData: keepPreviousData,
  });
};

export const useClearCache = () => {
  const queryClient = useQueryClient();
  const { enqueueSnackbar } = useSnackbar();

  return useMutation({
    mutationFn: (cacheType?: string) => systemService.clearCache(cacheType),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ["systemMetrics"] });
      enqueueSnackbar(`Cleared ${data.cleared} cache entries`, {
        variant: "success",
      });
    },
    onError: () => {
      enqueueSnackbar("Failed to clear cache", { variant: "error" });
    },
  });
};
