import { useQuery, useMutation, useQueryClient } from "react-query";
import {
  reportsService,
  type ReportFilters,
  type UpdateReportStatusRequest,
} from "@/services";
import { useSnackbar } from "notistack";

export const useReports = (filters: ReportFilters = {}) => {
  return useQuery({
    queryKey: ["reports", filters],
    queryFn: () => reportsService.getReports(filters),
    keepPreviousData: true,
  });
};

export const useReport = (id: string) => {
  return useQuery({
    queryKey: ["report", id],
    queryFn: () => reportsService.getReport(id),
    enabled: !!id,
  });
};

export const useReportStats = () => {
  return useQuery({
    queryKey: ["reportStats"],
    queryFn: reportsService.getReportStats,
    refetchInterval: 30000, // Refetch every 30 seconds
  });
};

export const useUpdateReportStatus = () => {
  const queryClient = useQueryClient();
  const { enqueueSnackbar } = useSnackbar();

  return useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: string;
      data: UpdateReportStatusRequest;
    }) => reportsService.updateReportStatus(id, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries(["reports"]);
      queryClient.invalidateQueries(["report", variables.id]);
      queryClient.invalidateQueries(["reportStats"]);
      enqueueSnackbar("Report status updated successfully", {
        variant: "success",
      });
    },
    onError: () => {
      enqueueSnackbar("Failed to update report status", { variant: "error" });
    },
  });
};

export const useDeleteReport = () => {
  const queryClient = useQueryClient();
  const { enqueueSnackbar } = useSnackbar();

  return useMutation({
    mutationFn: (id: string) => reportsService.deleteReport(id),
    onSuccess: () => {
      queryClient.invalidateQueries(["reports"]);
      queryClient.invalidateQueries(["reportStats"]);
      enqueueSnackbar("Report deleted successfully", { variant: "success" });
    },
    onError: () => {
      enqueueSnackbar("Failed to delete report", { variant: "error" });
    },
  });
};
