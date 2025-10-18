import { useQuery, useMutation, useQueryClient, keepPreviousData } from "@tanstack/react-query";
import {
  usersService,
  type UserFilters,
  type UpdateUserRequest,
} from "@/services";
import { useSnackbar } from "notistack";

export const useUsers = (filters: UserFilters = {}) => {
  return useQuery({
    queryKey: ["users", filters],
    queryFn: () => usersService.getUsers(filters),
    placeholderData: keepPreviousData,
  });
};

export const useUser = (id: string) => {
  return useQuery({
    queryKey: ["user", id],
    queryFn: () => usersService.getUser(id),
    enabled: !!id,
  });
};

export const useUserStats = () => {
  return useQuery({
    queryKey: ["userStats"],
    queryFn: usersService.getUserStats,
    refetchInterval: 30000,
  });
};

export const useUpdateUser = () => {
  const queryClient = useQueryClient();
  const { enqueueSnackbar } = useSnackbar();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateUserRequest }) =>
      usersService.updateUser(id, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["users"] });
      queryClient.invalidateQueries({ queryKey: ["user", variables.id] });
      queryClient.invalidateQueries({ queryKey: ["userStats"] });
      enqueueSnackbar("User updated successfully", { variant: "success" });
    },
    onError: () => {
      enqueueSnackbar("Failed to update user", { variant: "error" });
    },
  });
};

export const useDeleteUser = () => {
  const queryClient = useQueryClient();
  const { enqueueSnackbar } = useSnackbar();

  return useMutation({
    mutationFn: (id: string) => usersService.deleteUser(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["users"] });
      queryClient.invalidateQueries({ queryKey: ["userStats"] });
      enqueueSnackbar("User deleted successfully", { variant: "success" });
    },
    onError: () => {
      enqueueSnackbar("Failed to delete user", { variant: "error" });
    },
  });
};
