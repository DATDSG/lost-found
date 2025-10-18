import { useState, useMemo } from "react";
import {
  Box,
  Paper,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Chip,
  CircularProgress,
  IconButton,
  Switch,
  Checkbox,
  Toolbar,
  Tooltip,
  TableSortLabel,
  Menu,
  FormControlLabel,
  Divider,
  Badge,
  Button,
  TextField,
  MenuItem,
} from "@mui/material";
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  PersonAdd as ActivateIcon,
  PersonRemove as DeactivateIcon,
  FileDownload as ExportIcon,
  ViewColumn as ColumnIcon,
  FilterList as FilterIcon,
} from "@mui/icons-material";
import { format } from "date-fns";
import { useUsers, useNotification } from "@/hooks";
import { usersService } from "@/services/users.service";
import type { User } from "@/services/users.service";
import ConfirmDialog from "@/components/ConfirmDialog";

type Order = "asc" | "desc";
type OrderBy = keyof User | "";

interface Column {
  id: keyof User;
  label: string;
  visible: boolean;
  sortable: boolean;
}

export default function Users() {
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [order, setOrder] = useState<Order>("desc");
  const [orderBy, setOrderBy] = useState<OrderBy>("created_at");
  const [selected, setSelected] = useState<string[]>([]);
  const [columnMenuAnchor, setColumnMenuAnchor] = useState<null | HTMLElement>(
    null
  );
  const [searchQuery, setSearchQuery] = useState("");
  const [roleFilter, setRoleFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [confirmDialog, setConfirmDialog] = useState<{
    open: boolean;
    title: string;
    message: string;
    action: () => Promise<void>;
  }>({ open: false, title: "", message: "", action: async () => {} });
  const [loading, setLoading] = useState(false);

  const { showSuccess, showError, NotificationComponent } = useNotification();

  // Column visibility management
  const [columns, setColumns] = useState<Column[]>([
    { id: "id", label: "ID", visible: true, sortable: true },
    { id: "display_name", label: "Name", visible: true, sortable: true },
    { id: "email", label: "Email", visible: true, sortable: true },
    { id: "role", label: "Role", visible: true, sortable: true },
    { id: "is_active", label: "Active", visible: true, sortable: true },
    { id: "created_at", label: "Joined", visible: true, sortable: true },
  ]);

  const { data, isLoading, refetch } = useUsers({
    skip: page * rowsPerPage,
    limit: rowsPerPage,
    ...(roleFilter !== "all" && { role: roleFilter }),
    ...(statusFilter !== "all" && { is_active: statusFilter === "active" }),
  });

  const visibleColumns = columns.filter((col) => col.visible);
  const users = data?.items || [];

  // Sorting logic
  const sortedUsers = useMemo(() => {
    return [...users].sort((a, b) => {
      if (!orderBy) return 0;
      const aValue = a[orderBy];
      const bValue = b[orderBy];

      if (aValue === null || aValue === undefined) return 1;
      if (bValue === null || bValue === undefined) return -1;

      if (typeof aValue === "string" && typeof bValue === "string") {
        return order === "asc"
          ? aValue.localeCompare(bValue)
          : bValue.localeCompare(aValue);
      }

      if (typeof aValue === "boolean" && typeof bValue === "boolean") {
        return order === "asc"
          ? Number(aValue) - Number(bValue)
          : Number(bValue) - Number(aValue);
      }

      return order === "asc"
        ? aValue < bValue
          ? -1
          : 1
        : bValue < aValue
        ? -1
        : 1;
    });
  }, [users, order, orderBy]);

  // Search/filter logic
  const filteredUsers = useMemo(() => {
    return sortedUsers.filter((user) => {
      const matchesSearch =
        searchQuery === "" ||
        (user.display_name || "")
          .toLowerCase()
          .includes(searchQuery.toLowerCase()) ||
        user.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.role.toLowerCase().includes(searchQuery.toLowerCase());

      return matchesSearch;
    });
  }, [sortedUsers, searchQuery]);

  // Handlers
  const handleRequestSort = (property: keyof User) => {
    const isAsc = orderBy === property && order === "asc";
    setOrder(isAsc ? "desc" : "asc");
    setOrderBy(property);
  };

  const handleSelectAll = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.checked) {
      setSelected(filteredUsers.map((u) => u.id));
    } else {
      setSelected([]);
    }
  };

  const handleSelect = (id: string) => {
    const selectedIndex = selected.indexOf(id);
    let newSelected: string[] = [];

    if (selectedIndex === -1) {
      newSelected = [...selected, id];
    } else {
      newSelected = selected.filter((selectedId) => selectedId !== id);
    }

    setSelected(newSelected);
  };

  const handleToggleColumn = (columnId: keyof User) => {
    setColumns((prev) =>
      prev.map((col) =>
        col.id === columnId ? { ...col, visible: !col.visible } : col
      )
    );
  };

  const handleExport = () => {
    const headers = visibleColumns.map((col) => col.label);
    const rows = filteredUsers.map((user) =>
      visibleColumns.map((col) => {
        const value = user[col.id];
        if (col.id === "created_at") {
          return format(new Date(value as string), "yyyy-MM-dd");
        }
        if (typeof value === "boolean") {
          return value ? "Yes" : "No";
        }
        return `"${value || ""}"`;
      })
    );

    const csv = [headers, ...rows].map((row) => row.join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `users-${format(new Date(), "yyyy-MM-dd")}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleBulkDelete = () => {
    setConfirmDialog({
      open: true,
      title: "Delete Users",
      message: `Are you sure you want to delete ${selected.length} user(s)? This action cannot be undone.`,
      action: async () => {
        setLoading(true);
        try {
          const result = await usersService.bulkDelete(selected);
          showSuccess(`Successfully deleted ${result.success} user(s)`);
          if (result.failed > 0) {
            showError(`Failed to delete ${result.failed} user(s)`);
          }
          refetch();
          setSelected([]);
        } catch (error) {
          showError("Failed to delete users");
        } finally {
          setLoading(false);
        }
      },
    });
  };

  const handleBulkActivate = () => {
    setConfirmDialog({
      open: true,
      title: "Activate Users",
      message: `Are you sure you want to activate ${selected.length} user(s)?`,
      action: async () => {
        setLoading(true);
        try {
          const result = await usersService.bulkActivate(selected);
          showSuccess(`Successfully activated ${result.success} user(s)`);
          if (result.failed > 0) {
            showError(`Failed to activate ${result.failed} user(s)`);
          }
          refetch();
          setSelected([]);
        } catch (error) {
          showError("Failed to activate users");
        } finally {
          setLoading(false);
        }
      },
    });
  };

  const handleBulkDeactivate = () => {
    setConfirmDialog({
      open: true,
      title: "Deactivate Users",
      message: `Are you sure you want to deactivate ${selected.length} user(s)?`,
      action: async () => {
        setLoading(true);
        try {
          const result = await usersService.bulkDeactivate(selected);
          showSuccess(`Successfully deactivated ${result.success} user(s)`);
          if (result.failed > 0) {
            showError(`Failed to deactivate ${result.failed} user(s)`);
          }
          refetch();
          setSelected([]);
        } catch (error) {
          showError("Failed to deactivate users");
        } finally {
          setLoading(false);
        }
      },
    });
  };

  if (isLoading) {
    return (
      <Box
        display="flex"
        justifyContent="center"
        alignItems="center"
        minHeight="400px"
      >
        <CircularProgress />
      </Box>
    );
  }

  return (
    <>
      <Box>
        <Box
          display="flex"
          justifyContent="space-between"
          alignItems="center"
          mb={3}
        >
          <Typography variant="h4">Users</Typography>
          <Box display="flex" gap={1}>
            <Tooltip title="Toggle Columns">
              <IconButton onClick={(e) => setColumnMenuAnchor(e.currentTarget)}>
                <Badge
                  badgeContent={columns.filter((c) => !c.visible).length}
                  color="primary"
                >
                  <ColumnIcon />
                </Badge>
              </IconButton>
            </Tooltip>
            <Button
              variant="outlined"
              startIcon={<ExportIcon />}
              onClick={handleExport}
            >
              Export CSV
            </Button>
          </Box>
        </Box>

        {/* Column visibility menu */}
        <Menu
          anchorEl={columnMenuAnchor}
          open={Boolean(columnMenuAnchor)}
          onClose={() => setColumnMenuAnchor(null)}
        >
          <Box sx={{ px: 2, py: 1 }}>
            <Typography variant="subtitle2" gutterBottom>
              Toggle Columns
            </Typography>
            <Divider sx={{ mb: 1 }} />
            {columns.map((column) => (
              <FormControlLabel
                key={column.id}
                control={
                  <Switch
                    checked={column.visible}
                    onChange={() => handleToggleColumn(column.id)}
                    size="small"
                  />
                }
                label={column.label}
                sx={{ display: "block" }}
              />
            ))}
          </Box>
        </Menu>

        {/* Filters */}
        <Paper sx={{ p: 2, mb: 2 }}>
          <Box display="flex" gap={2} flexWrap="wrap">
            <TextField
              label="Search"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by name, email, role..."
              sx={{ minWidth: 300 }}
              size="small"
              InputProps={{
                startAdornment: (
                  <FilterIcon sx={{ mr: 1, color: "action.active" }} />
                ),
              }}
            />
            <TextField
              select
              label="Role"
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              sx={{ minWidth: 150 }}
              size="small"
            >
              <MenuItem value="all">All</MenuItem>
              <MenuItem value="admin">Admin</MenuItem>
              <MenuItem value="user">User</MenuItem>
              <MenuItem value="moderator">Moderator</MenuItem>
            </TextField>

            <TextField
              select
              label="Status"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              sx={{ minWidth: 150 }}
              size="small"
            >
              <MenuItem value="all">All</MenuItem>
              <MenuItem value="active">Active</MenuItem>
              <MenuItem value="inactive">Inactive</MenuItem>
            </TextField>
          </Box>
        </Paper>

        {/* Bulk actions toolbar */}
        {selected.length > 0 && (
          <Toolbar
            sx={{
              pl: { sm: 2 },
              pr: { xs: 1, sm: 1 },
              bgcolor: (theme) =>
                theme.palette.mode === "light"
                  ? "primary.lighter"
                  : "primary.darker",
              borderRadius: 1,
              mb: 2,
            }}
          >
            <Typography
              sx={{ flex: "1 1 100%" }}
              color="inherit"
              variant="subtitle1"
              component="div"
            >
              {selected.length} selected
            </Typography>
            <Tooltip title="Activate">
              <IconButton onClick={handleBulkActivate}>
                <ActivateIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Deactivate">
              <IconButton onClick={handleBulkDeactivate}>
                <DeactivateIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Delete">
              <IconButton onClick={handleBulkDelete}>
                <DeleteIcon />
              </IconButton>
            </Tooltip>
          </Toolbar>
        )}

        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell padding="checkbox">
                  <Checkbox
                    indeterminate={
                      selected.length > 0 &&
                      selected.length < filteredUsers.length
                    }
                    checked={
                      filteredUsers.length > 0 &&
                      selected.length === filteredUsers.length
                    }
                    onChange={handleSelectAll}
                  />
                </TableCell>
                {visibleColumns.map((column) => (
                  <TableCell key={column.id}>
                    {column.sortable ? (
                      <TableSortLabel
                        active={orderBy === column.id}
                        direction={orderBy === column.id ? order : "asc"}
                        onClick={() => handleRequestSort(column.id)}
                      >
                        {column.label}
                      </TableSortLabel>
                    ) : (
                      column.label
                    )}
                  </TableCell>
                ))}
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredUsers.map((user: User) => {
                const isSelected = selected.indexOf(user.id) !== -1;
                return (
                  <TableRow
                    key={user.id}
                    hover
                    onClick={() => handleSelect(user.id)}
                    selected={isSelected}
                    sx={{ cursor: "pointer" }}
                  >
                    <TableCell padding="checkbox">
                      <Checkbox checked={isSelected} />
                    </TableCell>
                    {visibleColumns.map((column) => {
                      const value = user[column.id];

                      if (column.id === "role") {
                        return (
                          <TableCell key={column.id}>
                            <Chip
                              label={value as string}
                              size="small"
                              color="primary"
                            />
                          </TableCell>
                        );
                      }

                      if (column.id === "is_active") {
                        return (
                          <TableCell key={column.id}>
                            <Switch
                              checked={value as boolean}
                              disabled
                              size="small"
                            />
                          </TableCell>
                        );
                      }

                      if (column.id === "created_at") {
                        return (
                          <TableCell key={column.id}>
                            {format(new Date(value as string), "MMM dd, yyyy")}
                          </TableCell>
                        );
                      }

                      return (
                        <TableCell key={column.id}>
                          {(value as string) || "N/A"}
                        </TableCell>
                      );
                    })}
                    <TableCell onClick={(e) => e.stopPropagation()}>
                      <Tooltip title="Edit User">
                        <IconButton size="small">
                          <EditIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
          <TablePagination
            component="div"
            count={data?.total || 0}
            page={page}
            onPageChange={(_, newPage) => setPage(newPage)}
            rowsPerPage={rowsPerPage}
            onRowsPerPageChange={(e) => {
              setRowsPerPage(parseInt(e.target.value, 10));
              setPage(0);
            }}
          />
        </TableContainer>
      </Box>

      <ConfirmDialog
        open={confirmDialog.open}
        title={confirmDialog.title}
        message={confirmDialog.message}
        confirmText="Confirm"
        cancelText="Cancel"
        confirmColor="error"
        loading={loading}
        onConfirm={async () => {
          await confirmDialog.action();
          setConfirmDialog({ ...confirmDialog, open: false });
        }}
        onCancel={() => setConfirmDialog({ ...confirmDialog, open: false })}
      />

      <NotificationComponent />
    </>
  );
}
