import {
  useQuery,
  useMutation,
  useQueryClient,
  keepPreviousData,
} from "@tanstack/react-query";
import { matchesService, type MatchFilters } from "@/services";
import { useSnackbar } from "notistack";

export const useMatches = (filters: MatchFilters = {}) => {
  return useQuery({
    queryKey: ["matches", filters],
    queryFn: () => matchesService.getMatches(filters),
    placeholderData: keepPreviousData,
  });
};

export const useMatch = (id: string) => {
  return useQuery({
    queryKey: ["match", id],
    queryFn: () => matchesService.getMatch(id),
    enabled: !!id,
  });
};

export const useMatchStats = () => {
  return useQuery({
    queryKey: ["matchStats"],
    queryFn: matchesService.getMatchStats,
    refetchInterval: 30000,
  });
};

export const useTriggerMatching = () => {
  const queryClient = useQueryClient();
  const { enqueueSnackbar } = useSnackbar();

  return useMutation({
    mutationFn: (reportId: string) => matchesService.triggerMatching(reportId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["matches"] });
      queryClient.invalidateQueries({ queryKey: ["matchStats"] });
      enqueueSnackbar("Matching triggered successfully", {
        variant: "success",
      });
    },
    onError: () => {
      enqueueSnackbar("Failed to trigger matching", { variant: "error" });
    },
  });
};
