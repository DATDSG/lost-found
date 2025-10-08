import {
  Box,
  Paper,
  Typography,
  Grid,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  LinearProgress,
} from "@mui/material";
import {
  Storage as StorageIcon,
  Memory as MemoryIcon,
  Speed as SpeedIcon,
} from "@mui/icons-material";
import { useSystemHealth } from "@/hooks/useSystem";

export default function System() {
  const { data: health, isLoading } = useSystemHealth();

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

  const getServiceStatus = (status: string) => {
    return status === "healthy" || status === "connected" ? "success" : "error";
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        System Health
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Service Status
            </Typography>
            <Grid container spacing={2} sx={{ mt: 1 }}>
              {health?.services &&
                Object.entries(health.services).map(([service, status]) => (
                  <Grid item xs={12} sm={6} md={3} key={service}>
                    <Box
                      sx={{
                        p: 2,
                        border: 1,
                        borderColor: "divider",
                        borderRadius: 1,
                      }}
                    >
                      <Typography
                        variant="body2"
                        color="text.secondary"
                        gutterBottom
                      >
                        {service.replace("_", " ").toUpperCase()}
                      </Typography>
                      <Chip
                        label={status.status}
                        size="small"
                        color={getServiceStatus(status.status)}
                        sx={{ mt: 1 }}
                      />
                    </Box>
                  </Grid>
                ))}
            </Grid>
          </Paper>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <SpeedIcon sx={{ mr: 1, color: "primary.main" }} />
                <Typography variant="h6">CPU Usage</Typography>
              </Box>
              <Typography variant="h3" gutterBottom>
                {/* Note: CPU/Memory/Disk metrics not available in current API */}
                0%
              </Typography>
              <LinearProgress
                variant="determinate"
                value={0}
                color="success"
                sx={{ height: 8, borderRadius: 4 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <MemoryIcon sx={{ mr: 1, color: "secondary.main" }} />
                <Typography variant="h6">Memory Usage</Typography>
              </Box>
              <Typography variant="h3" gutterBottom>
                {/* Note: CPU/Memory/Disk metrics not available in current API */}
                0%
              </Typography>
              <LinearProgress
                variant="determinate"
                value={0}
                color="success"
                sx={{ height: 8, borderRadius: 4 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <StorageIcon sx={{ mr: 1, color: "success.main" }} />
                <Typography variant="h6">Disk Usage</Typography>
              </Box>
              <Typography variant="h3" gutterBottom>
                {/* Note: CPU/Memory/Disk metrics not available in current API */}
                0%
              </Typography>
              <LinearProgress
                variant="determinate"
                value={0}
                color="success"
                sx={{ height: 8, borderRadius: 4 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Overall System Status
            </Typography>
            <Chip
              label={health?.status?.toUpperCase()}
              color={health?.status === "healthy" ? "success" : "error"}
              size="medium"
              sx={{ mt: 1 }}
            />
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
