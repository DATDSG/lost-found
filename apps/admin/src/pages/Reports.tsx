import { useState } from "react";
import { Link } from "react-router-dom";
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
  TextField,
  MenuItem,
  Button,
  CircularProgress,
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
} from "@mui/material";
import {
  Visibility as ViewIcon,
  Delete as DeleteIcon,
  CheckCircle as ApproveIcon,
  Block as RejectIcon,
  FileDownload as ExportIcon,
  ViewColumn as ColumnIcon,
  FilterList as FilterIcon,
} from "@mui/icons-material";
import { format } from "date-fns";
import { useReports } from "@/hooks";
import type {
  Report,
  ReportType,
  ReportStatus,
} from "@/services/reports.service";

type Order = "asc" | "desc";
type OrderBy = keyof Report | "";

interface Column {
  id: keyof Report;
  label: string;
  visible: boolean;
  sortable: boolean;
}

export default function Reports() {
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [status, setStatus] = useState<string>("all");
  const [type, setType] = useState<string>("all");
  const [order, setOrder] = useState<Order>("desc");
  const [orderBy, setOrderBy] = useState<OrderBy>("created_at");
  const [selected, setSelected] = useState<string[]>([]);
  const [columnMenuAnchor, setColumnMenuAnchor] = useState<null | HTMLElement>(
    null
  );
  const [searchQuery, setSearchQuery] = useState("");

  // Column visibility management
  const [columns, setColumns] = useState<Column[]>([
    { id: "id", label: "ID", visible: true, sortable: true },
    { id: "title", label: "Title", visible: true, sortable: true },
    { id: "type", label: "Type", visible: true, sortable: true },
    { id: "status", label: "Status", visible: true, sortable: true },
    { id: "category", label: "Category", visible: true, sortable: true },
    { id: "location", label: "Location", visible: true, sortable: true },
    { id: "created_at", label: "Created", visible: true, sortable: true },
  ]);

  const { data, isLoading } = useReports({
    skip: page * rowsPerPage,
    limit: rowsPerPage,
    ...(status !== "all" && { status: status as ReportStatus }),
    ...(type !== "all" && { type: type as ReportType }),
  });

  const visibleColumns = columns.filter((col) => col.visible);
  const reports = data?.items || [];

  // Sorting logic
  const sortedReports = [...reports].sort((a, b) => {
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

    return order === "asc"
      ? aValue < bValue
        ? -1
        : 1
      : bValue < aValue
      ? -1
      : 1;
  });

  // Filter by search query
  const filteredReports = sortedReports.filter(
    (report) =>
      searchQuery === "" ||
      report.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      report.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
      report.location.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Selection handlers
  const handleSelectAll = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.checked) {
      setSelected(filteredReports.map((r) => r.id));
    } else {
      setSelected([]);
    }
  };

  const handleSelect = (id: string) => {
    const selectedIndex = selected.indexOf(id);
    let newSelected: string[] = [];

    if (selectedIndex === -1) {
      newSelected = newSelected.concat(selected, id);
    } else if (selectedIndex === 0) {
      newSelected = newSelected.concat(selected.slice(1));
    } else if (selectedIndex === selected.length - 1) {
      newSelected = newSelected.concat(selected.slice(0, -1));
    } else if (selectedIndex > 0) {
      newSelected = newSelected.concat(
        selected.slice(0, selectedIndex),
        selected.slice(selectedIndex + 1)
      );
    }

    setSelected(newSelected);
  };

  // Sort handler
  const handleRequestSort = (property: keyof Report) => {
    const isAsc = orderBy === property && order === "asc";
    setOrder(isAsc ? "desc" : "asc");
    setOrderBy(property);
  };

  // Column visibility toggle
  const handleToggleColumn = (columnId: keyof Report) => {
    setColumns((prev) =>
      prev.map((col) =>
        col.id === columnId ? { ...col, visible: !col.visible } : col
      )
    );
  };

  // Export to CSV
  const handleExport = () => {
    const csvContent = [
      // Header
      visibleColumns.map((col) => col.label).join(","),
      // Data rows
      ...filteredReports.map((report) =>
        visibleColumns
          .map((col) => {
            const value = report[col.id];
            if (value === null || value === undefined) return "";
            if (col.id === "created_at") {
              return format(new Date(value as string), "yyyy-MM-dd");
            }
            if (Array.isArray(value)) return value.join("; ");
            return `"${value}"`;
          })
          .join(",")
      ),
    ].join("\n");

    const blob = new Blob([csvContent], { type: "text/csv" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `reports-${format(new Date(), "yyyy-MM-dd")}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
  };

  // Bulk actions
  const handleBulkDelete = () => {
    console.log("Bulk delete:", selected);
    // TODO: Implement bulk delete API call
    setSelected([]);
  };

  const handleBulkApprove = () => {
    console.log("Bulk approve:", selected);
    // TODO: Implement bulk approve API call
    setSelected([]);
  };

  const handleBulkReject = () => {
    console.log("Bulk reject:", selected);
    // TODO: Implement bulk reject API call
    setSelected([]);
  };

  const getStatusColor = (status: string) => {
    const colors: Record<string, "default" | "warning" | "success" | "error"> =
      {
        pending: "warning",
        approved: "success",
        rejected: "error",
        resolved: "default",
      };
    return colors[status] || "default";
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
    <Box>
      <Box
        display="flex"
        justifyContent="space-between"
        alignItems="center"
        mb={3}
      >
        <Typography variant="h4">Reports</Typography>
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
            placeholder="Search by title, category, location..."
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
            value={status}
            onChange={(e) => setStatus(e.target.value)}
            sx={{ minWidth: 150 }}
            size="small"
          >
            <MenuItem value="all">All</MenuItem>
            <MenuItem value="pending">Pending</MenuItem>
            <MenuItem value="approved">Approved</MenuItem>
            <MenuItem value="hidden">Hidden</MenuItem>
            <MenuItem value="removed">Removed</MenuItem>
          </TextField>

          <TextField
            select
            label="Type"
            value={type}
            onChange={(e) => setType(e.target.value)}
            sx={{ minWidth: 150 }}
            size="small"
          >
            <MenuItem value="all">All</MenuItem>
            <MenuItem value="lost">Lost</MenuItem>
            <MenuItem value="found">Found</MenuItem>
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
                    selected.length < filteredReports.length
                  }
                  checked={
                    filteredReports.length > 0 &&
                    selected.length === filteredReports.length
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
            {filteredReports.map((report: Report) => {
              const isSelected = selected.indexOf(report.id) !== -1;
              return (
                <TableRow
                  key={report.id}
                  hover
                  onClick={() => handleSelect(report.id)}
                  role="checkbox"
                  aria-checked={isSelected}
                  selected={isSelected}
                  sx={{ cursor: "pointer" }}
                >
                  <TableCell padding="checkbox">
                    <Checkbox checked={isSelected} />
                  </TableCell>
                  {visibleColumns.map((column) => {
                    const value = report[column.id];

                    if (column.id === "type") {
                      return (
                        <TableCell key={column.id}>
                          <Chip
                            label={value as string}
                            size="small"
                            color={value === "lost" ? "error" : "success"}
                          />
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
                      <TableCell key={column.id}>
                        {Array.isArray(value)
                          ? value.join(", ")
                          : (value as string)}
                      </TableCell>
                    );
                  })}
                  <TableCell onClick={(e) => e.stopPropagation()}>
                    <Tooltip title="View Details">
                      <IconButton
                        component={Link}
                        to={`/reports/${report.id}`}
                        size="small"
                      >
                        <ViewIcon />
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
  );
}
