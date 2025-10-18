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
  TextField,
  IconButton,
  Button,
  Tooltip,
  Badge,
  Menu,
  FormControlLabel,
  Switch,
  Divider,
  TableSortLabel,
} from "@mui/material";
import {
  ViewColumn as ColumnIcon,
  FileDownload as ExportIcon,
  FilterList as FilterIcon,
} from "@mui/icons-material";
import { format } from "date-fns";
import { useAuditLogs } from "@/hooks";
import { useNotification } from "@/hooks/useNotification";
import type { AuditLogEntry } from "@/services/system.service";

type Order = "asc" | "desc";

interface Column {
  id: keyof AuditLogEntry | "user" | "resource";
  label: string;
  visible: boolean;
  sortable: boolean;
}

export default function AuditLog() {
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [search, setSearch] = useState("");
  const [order, setOrder] = useState<Order>("desc");
  const [orderBy, setOrderBy] = useState<keyof AuditLogEntry>("created_at");
  const [columnMenuAnchor, setColumnMenuAnchor] = useState<null | HTMLElement>(
    null
  );
  const { showSuccess, showError, NotificationComponent } = useNotification();

  const [columns, setColumns] = useState<Column[]>([
    { id: "created_at", label: "Timestamp", visible: true, sortable: true },
    { id: "user", label: "User", visible: true, sortable: false },
    { id: "action", label: "Action", visible: true, sortable: true },
    { id: "resource", label: "Resource", visible: true, sortable: false },
    { id: "ip_address", label: "IP Address", visible: true, sortable: true },
    { id: "details", label: "Details", visible: true, sortable: false },
  ]);

  const { data, isLoading } = useAuditLogs({
    skip: page * rowsPerPage,
    limit: rowsPerPage,
    ...(search && { search }),
  });

  const visibleColumns = columns.filter((col) => col.visible);

  // Sort data
  const sortedLogs = useMemo(() => {
    if (!data?.items) return [];

    const comparator = (a: AuditLogEntry, b: AuditLogEntry) => {
      let aValue: any = a[orderBy];
      let bValue: any = b[orderBy];

      // Handle null/undefined
      if (aValue == null) return 1;
      if (bValue == null) return -1;

      // Handle dates
      if (orderBy === "created_at") {
        aValue = new Date(aValue).getTime();
        bValue = new Date(bValue).getTime();
      }

      if (bValue < aValue) {
        return order === "desc" ? -1 : 1;
      }
      if (bValue > aValue) {
        return order === "desc" ? 1 : -1;
      }
      return 0;
    };

    return [...data.items].sort(comparator);
  }, [data?.items, order, orderBy]);

  const handleRequestSort = (property: keyof AuditLogEntry) => {
    const isAsc = orderBy === property && order === "asc";
    setOrder(isAsc ? "desc" : "asc");
    setOrderBy(property);
  };

  const handleToggleColumn = (columnId: string) => {
    setColumns(
      columns.map((col) =>
        col.id === columnId ? { ...col, visible: !col.visible } : col
      )
    );
  };

  const handleExport = () => {
    try {
      if (!data?.items || data.items.length === 0) {
        showError("No data to export");
        return;
      }

      // Create CSV content
      const headers = visibleColumns.map((col) => col.label).join(",");
      const rows = sortedLogs.map((log) => {
        return visibleColumns
          .map((col) => {
            if (col.id === "created_at") {
              return format(new Date(log.created_at), "yyyy-MM-dd HH:mm:ss");
            }
            if (col.id === "user") {
              return log.user?.display_name || log.user?.email || "System";
            }
            if (col.id === "resource") {
              return `${log.resource_type} #${log.resource_id}`;
            }
            if (col.id === "details") {
              return JSON.stringify(log.details);
            }
            return log[col.id as keyof AuditLogEntry];
          })
          .map((val) => `"${String(val).replace(/"/g, '""')}"`)
          .join(",");
      });

      const csv = [headers, ...rows].join("\n");
      const blob = new Blob([csv], { type: "text/csv" });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `audit-log-${format(new Date(), "yyyy-MM-dd")}.csv`;
      a.click();
      window.URL.revokeObjectURL(url);

      showSuccess("Audit log exported successfully");
    } catch (error) {
      console.error("Export error:", error);
      showError("Failed to export audit log");
    }
  };

  const getActionColor = (action: string) => {
    if (action.includes("create")) return "success";
    if (action.includes("update")) return "info";
    if (action.includes("delete")) return "error";
    return "default";
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
          <Typography variant="h4">Audit Log</Typography>
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

        {/* Search */}
        <Paper sx={{ p: 2, mb: 2 }}>
          <TextField
            label="Search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by action, resource, or user..."
            sx={{ minWidth: 300 }}
            size="small"
            InputProps={{
              startAdornment: (
                <FilterIcon sx={{ mr: 1, color: "action.active" }} />
              ),
            }}
          />
        </Paper>

        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                {visibleColumns.map((column) => (
                  <TableCell key={column.id}>
                    {column.sortable ? (
                      <TableSortLabel
                        active={orderBy === column.id}
                        direction={orderBy === column.id ? order : "asc"}
                        onClick={() =>
                          handleRequestSort(column.id as keyof AuditLogEntry)
                        }
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
              {sortedLogs.map((log: AuditLogEntry) => (
                <TableRow key={log.id}>
                  {visibleColumns.map((column) => {
                    if (column.id === "created_at") {
                      return (
                        <TableCell key={column.id}>
                          {format(
                            new Date(log.created_at),
                            "MMM dd, yyyy HH:mm:ss"
                          )}
                        </TableCell>
                      );
                    }

                    if (column.id === "user") {
                      return (
                        <TableCell key={column.id}>
                          {log.user?.display_name ||
                            log.user?.email ||
                            "System"}
                        </TableCell>
                      );
                    }

                    if (column.id === "action") {
                      return (
                        <TableCell key={column.id}>
                          <Chip
                            label={log.action}
                            size="small"
                            color={getActionColor(log.action)}
                          />
                        </TableCell>
                      );
                    }

                    if (column.id === "resource") {
                      return (
                        <TableCell key={column.id}>
                          {log.resource_type} #{log.resource_id}
                        </TableCell>
                      );
                    }

                    if (column.id === "ip_address") {
                      return (
                        <TableCell key={column.id}>
                          <Typography
                            variant="caption"
                            sx={{ fontFamily: "monospace" }}
                          >
                            {log.ip_address}
                          </Typography>
                        </TableCell>
                      );
                    }

                    if (column.id === "details") {
                      return (
                        <TableCell key={column.id}>
                          <Typography variant="caption">
                            {JSON.stringify(log.details).substring(0, 50)}...
                          </Typography>
                        </TableCell>
                      );
                    }

                    return <TableCell key={column.id} />;
                  })}
                </TableRow>
              ))}
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

      <NotificationComponent />
    </>
  );
}
