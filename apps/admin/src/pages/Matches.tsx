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
  LinearProgress,
  Checkbox,
  IconButton,
  Toolbar,
  Tooltip,
  TableSortLabel,
  Menu,
  FormControlLabel,
  Switch,
  Divider,
  Badge,
  Button,
  TextField,
  MenuItem,
} from "@mui/material";
import {
  CheckCircle as ApproveIcon,
  Block as RejectIcon,
  Notifications as NotifyIcon,
  FileDownload as ExportIcon,
  ViewColumn as ColumnIcon,
  FilterList as FilterIcon,
} from "@mui/icons-material";
import { format } from "date-fns";
import { useMatches, useNotification } from "@/hooks";
import { matchesService } from "@/services/matches.service";
import type { Match } from "@/services/matches.service";
import ConfirmDialog from "@/components/ConfirmDialog";

type Order = "asc" | "desc";
type OrderBy = keyof Match | "";

interface Column {
  id: keyof Match;
  label: string;
  visible: boolean;
  sortable: boolean;
}

export default function Matches() {
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [order, setOrder] = useState<Order>("desc");
  const [orderBy, setOrderBy] = useState<OrderBy>("overall_score");
  const [selected, setSelected] = useState<string[]>([]);
  const [columnMenuAnchor, setColumnMenuAnchor] = useState<null | HTMLElement>(
    null
  );
  const [searchQuery, setSearchQuery] = useState("");
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
    {
      id: "lost_report_id",
      label: "Lost Report",
      visible: true,
      sortable: false,
    },
    {
      id: "found_report_id",
      label: "Found Report",
      visible: true,
      sortable: false,
    },
    { id: "overall_score", label: "Score", visible: true, sortable: true },
    { id: "visual_similarity", label: "Visual", visible: true, sortable: true },
    { id: "text_similarity", label: "Text", visible: true, sortable: true },
    { id: "location_score", label: "Location", visible: true, sortable: true },
    { id: "status", label: "Status", visible: true, sortable: true },
    { id: "created_at", label: "Created", visible: true, sortable: true },
  ]);

  const { data, isLoading, refetch } = useMatches({
    skip: page * rowsPerPage,
    limit: rowsPerPage,
    ...(statusFilter !== "all" && { status: statusFilter }),
  });

  const visibleColumns = columns.filter((col) => col.visible);
  const matches = data?.items || [];

  // Sorting logic
  const sortedMatches = useMemo(() => {
    return [...matches].sort((a, b) => {
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

      if (typeof aValue === "number" && typeof bValue === "number") {
        return order === "asc" ? aValue - bValue : bValue - aValue;
      }

      return 0;
    });
  }, [matches, order, orderBy]);

  // Search/filter logic
  const filteredMatches = useMemo(() => {
    return sortedMatches.filter((match) => {
      const matchesSearch =
        searchQuery === "" ||
        match.lost_report?.title
          ?.toLowerCase()
          .includes(searchQuery.toLowerCase()) ||
        match.found_report?.title
          ?.toLowerCase()
          .includes(searchQuery.toLowerCase()) ||
        match.id.toLowerCase().includes(searchQuery.toLowerCase());

      return matchesSearch;
    });
  }, [sortedMatches, searchQuery]);

  // Handlers
  const handleRequestSort = (property: keyof Match) => {
    const isAsc = orderBy === property && order === "asc";
    setOrder(isAsc ? "desc" : "asc");
    setOrderBy(property);
  };

  const handleSelectAll = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.checked) {
      setSelected(filteredMatches.map((m) => m.id));
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

  const handleToggleColumn = (columnId: keyof Match) => {
    setColumns((prev) =>
      prev.map((col) =>
        col.id === columnId ? { ...col, visible: !col.visible } : col
      )
    );
  };

  const handleExport = () => {
    const headers = visibleColumns.map((col) => col.label);
    const rows = filteredMatches.map((match) =>
      visibleColumns.map((col) => {
        const value = match[col.id];
        if (col.id === "created_at") {
          return format(new Date(value as string), "yyyy-MM-dd");
        }
        if (typeof value === "number") {
          return col.id.includes("score") || col.id.includes("similarity")
            ? (value * 100).toFixed(1)
            : value;
        }
        if (col.id === "lost_report_id" && match.lost_report) {
          return `"${match.lost_report.title || match.lost_report_id}"`;
        }
        if (col.id === "found_report_id" && match.found_report) {
          return `"${match.found_report.title || match.found_report_id}"`;
        }
        return `"${value || ""}"`;
      })
    );

    const csv = [headers, ...rows].map((row) => row.join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `matches-${format(new Date(), "yyyy-MM-dd")}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleBulkApprove = () => {
    setConfirmDialog({
      open: true,
      title: "Approve Matches",
      message: `Are you sure you want to approve ${selected.length} match(es)?`,
      action: async () => {
        setLoading(true);
        try {
          const result = await matchesService.bulkApprove(selected);
          showSuccess(`Successfully approved ${result.success} match(es)`);
          if (result.failed > 0) {
            showError(`Failed to approve ${result.failed} match(es)`);
          }
          refetch();
          setSelected([]);
        } catch (error) {
          showError("Failed to approve matches");
        } finally {
          setLoading(false);
        }
      },
    });
  };

  const handleBulkReject = () => {
    setConfirmDialog({
      open: true,
      title: "Reject Matches",
      message: `Are you sure you want to reject ${selected.length} match(es)?`,
      action: async () => {
        setLoading(true);
        try {
          const result = await matchesService.bulkReject(selected);
          showSuccess(`Successfully rejected ${result.success} match(es)`);
          if (result.failed > 0) {
            showError(`Failed to reject ${result.failed} match(es)`);
          }
          refetch();
          setSelected([]);
        } catch (error) {
          showError("Failed to reject matches");
        } finally {
          setLoading(false);
        }
      },
    });
  };

  const handleBulkNotify = () => {
    setConfirmDialog({
      open: true,
      title: "Notify Users",
      message: `Send notifications to users for ${selected.length} match(es)?`,
      action: async () => {
        setLoading(true);
        try {
          const result = await matchesService.bulkNotify(selected);
          showSuccess(
            `Successfully notified users for ${result.success} match(es)`
          );
          if (result.failed > 0) {
            showError(`Failed to notify ${result.failed} match(es)`);
          }
          refetch();
          setSelected([]);
        } catch (error) {
          showError("Failed to send notifications");
        } finally {
          setLoading(false);
        }
      },
    });
  };

  const getStatusColor = (status: string) => {
    const colors: Record<string, "default" | "info" | "success" | "error"> = {
      pending: "info",
      promoted: "default",
      confirmed: "success",
      rejected: "error",
    };
    return colors[status] || "default";
  };

  const getScoreColor = (score: number) => {
    if (score >= 0.8) return "success";
    if (score >= 0.6) return "warning";
    return "error";
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
          <Typography variant="h4">Matches</Typography>
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
              placeholder="Search by report title or ID..."
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
              label="Status"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              sx={{ minWidth: 150 }}
              size="small"
            >
              <MenuItem value="all">All</MenuItem>
              <MenuItem value="pending">Pending</MenuItem>
              <MenuItem value="promoted">Promoted</MenuItem>
              <MenuItem value="confirmed">Confirmed</MenuItem>
              <MenuItem value="rejected">Rejected</MenuItem>
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
            <Tooltip title="Approve">
              <IconButton onClick={handleBulkApprove}>
                <ApproveIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Reject">
              <IconButton onClick={handleBulkReject}>
                <RejectIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Notify Users">
              <IconButton onClick={handleBulkNotify}>
                <NotifyIcon />
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
                      selected.length < filteredMatches.length
                    }
                    checked={
                      filteredMatches.length > 0 &&
                      selected.length === filteredMatches.length
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
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredMatches.map((match: Match) => {
                const isSelected = selected.indexOf(match.id) !== -1;
                return (
                  <TableRow
                    key={match.id}
                    hover
                    onClick={() => handleSelect(match.id)}
                    selected={isSelected}
                    sx={{ cursor: "pointer" }}
                  >
                    <TableCell padding="checkbox">
                      <Checkbox checked={isSelected} />
                    </TableCell>
                    {visibleColumns.map((column) => {
                      const value = match[column.id];

                      if (column.id === "lost_report_id") {
                        return (
                          <TableCell key={column.id}>
                            {match.lost_report?.title ||
                              `#${match.lost_report_id}`}
                          </TableCell>
                        );
                      }

                      if (column.id === "found_report_id") {
                        return (
                          <TableCell key={column.id}>
                            {match.found_report?.title ||
                              `#${match.found_report_id}`}
                          </TableCell>
                        );
                      }

                      if (column.id === "overall_score") {
                        return (
                          <TableCell key={column.id}>
                            <Box sx={{ width: 100 }}>
                              <LinearProgress
                                variant="determinate"
                                value={(value as number) * 100}
                                color={getScoreColor(value as number)}
                              />
                              <Typography variant="caption">
                                {((value as number) * 100).toFixed(1)}%
                              </Typography>
                            </Box>
                          </TableCell>
                        );
                      }

                      if (column.id === "visual_similarity") {
                        return (
                          <TableCell key={column.id}>
                            {value
                              ? `${((value as number) * 100).toFixed(0)}%`
                              : "N/A"}
                          </TableCell>
                        );
                      }

                      if (
                        column.id === "text_similarity" ||
                        column.id === "location_score"
                      ) {
                        return (
                          <TableCell key={column.id}>
                            {((value as number) * 100).toFixed(0)}%
                          </TableCell>
                        );
                      }

                      if (column.id === "status") {
                        return (
                          <TableCell key={column.id}>
                            <Chip
                              label={value as string}
                              size="small"
                              color={getStatusColor(value as string)}
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
                        <TableCell key={column.id}>{value as string}</TableCell>
                      );
                    })}
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
        confirmColor="primary"
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
