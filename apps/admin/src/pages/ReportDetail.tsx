import { useParams } from "react-router-dom";
import {
  Box,
  Paper,
  Typography,
  Grid,
  Chip,
  Button,
  CircularProgress,
  Card,
  CardContent,
  CardMedia,
} from "@mui/material";
import { format } from "date-fns";
import { useReport, useUpdateReportStatus } from "@/hooks/useReports";

export default function ReportDetail() {
  const { id } = useParams();
  const { data: report, isPending } = useReport(id || "");
  const updateStatus = useUpdateReportStatus();

  if (isPending) {
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

  if (!report) {
    return <Typography>Report not found</Typography>;
  }

  return (
    <Box>
      <Box
        display="flex"
        justifyContent="space-between"
        alignItems="center"
        mb={3}
      >
        <Typography variant="h4">Report Details</Typography>
        {report.status === "pending" && (
          <Box display="flex" gap={2}>
            <Button
              variant="contained"
              color="success"
              onClick={() =>
                updateStatus.mutate({
                  id: id!,
                  data: { status: "approved" },
                })
              }
              disabled={updateStatus.isPending}
            >
              Approve
            </Button>
            <Button
              variant="contained"
              color="error"
              onClick={() =>
                updateStatus.mutate({
                  id: id!,
                  data: { status: "hidden" },
                })
              }
              disabled={updateStatus.isPending}
            >
              Reject
            </Button>
          </Box>
        )}
      </Box>

      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h5" gutterBottom>
              {report.title}
            </Typography>

            <Box display="flex" gap={1} mb={2}>
              <Chip
                label={report.type}
                color={report.type === "lost" ? "error" : "success"}
              />
              <Chip label={report.status} />
              <Chip label={report.category} variant="outlined" />
            </Box>

            <Typography variant="body1" paragraph>
              {report.description}
            </Typography>

            <Grid container spacing={2} sx={{ mt: 2 }}>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  Location
                </Typography>
                <Typography variant="body1">{report.location}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  Date Occurred
                </Typography>
                <Typography variant="body1">
                  {format(new Date(report.date_occurred), "MMM dd, yyyy")}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  Created At
                </Typography>
                <Typography variant="body1">
                  {format(new Date(report.created_at), "MMM dd, yyyy HH:mm")}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  User
                </Typography>
                <Typography variant="body1">
                  {report.user?.display_name || report.user?.email || "Unknown"}
                </Typography>
              </Grid>
            </Grid>
          </Paper>
        </Grid>

        <Grid item xs={12} md={4}>
          {report.media_urls && report.media_urls.length > 0 && (
            <Card>
              <CardMedia
                component="img"
                image={report.media_urls[0]}
                alt={report.title}
                sx={{ height: 300, objectFit: "cover" }}
              />
              <CardContent>
                <Typography variant="subtitle2">Report Image</Typography>
              </CardContent>
            </Card>
          )}
        </Grid>
      </Grid>
    </Box>
  );
}
