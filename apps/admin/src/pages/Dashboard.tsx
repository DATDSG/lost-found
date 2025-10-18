import {
  Grid,
  Paper,
  Typography,
  Box,
  Card,
  CardContent,
  Skeleton,
  Chip,
  List,
  ListItem,
  ListItemText,
  Divider,
} from "@mui/material";
import {
  People as PeopleIcon,
  Description as ReportsIcon,
  Link as MatchesIcon,
  CheckCircle as CheckIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
} from "@mui/icons-material";
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import { useReportStats, useUserStats, useMatchStats } from "@/hooks";

export default function Dashboard() {
  const { data: reportStats, isLoading: loadingReports } = useReportStats();
  const { data: userStats, isLoading: loadingUsers } = useUserStats();
  const { data: matchStats, isLoading: loadingMatches } = useMatchStats();

  const isLoading = loadingReports || loadingUsers || loadingMatches;

  // Mock data for charts (in real app, this would come from API)
  const reportsOverTimeData = [
    { name: "Mon", reports: 12, matches: 8 },
    { name: "Tue", reports: 19, matches: 12 },
    { name: "Wed", reports: 15, matches: 10 },
    { name: "Thu", reports: 22, matches: 15 },
    { name: "Fri", reports: 28, matches: 18 },
    { name: "Sat", reports: 18, matches: 14 },
    { name: "Sun", reports: 14, matches: 9 },
  ];

  const categoryData = [
    { name: "Electronics", value: 45 },
    { name: "Personal Items", value: 30 },
    { name: "Documents", value: 15 },
    { name: "Pets", value: 10 },
  ];

  const matchStatusData = [
    { name: "Pending Review", value: matchStats?.pending || 12 },
    { name: "Confirmed", value: matchStats?.confirmed || 8 },
    { name: "Rejected", value: matchStats?.rejected || 4 },
  ];

  const recentActivity = [
    {
      type: "New Report",
      title: "iPhone 14 Pro found in Library",
      time: "5 minutes ago",
    },
    {
      type: "Match Confirmed",
      title: "Wallet matched with owner",
      time: "1 hour ago",
    },
    {
      type: "New User",
      title: "john.doe@example.com registered",
      time: "2 hours ago",
    },
    {
      type: "Report Updated",
      title: "Keys status changed to found",
      time: "3 hours ago",
    },
    {
      type: "New Report",
      title: "Laptop bag lost in Cafeteria",
      time: "4 hours ago",
    },
  ];

  const COLORS = ["#0088FE", "#00C49F", "#FFBB28", "#FF8042", "#8884d8"];

  // Calculate trends (mock data - should come from API)
  const calculateTrend = (_current: number) => {
    const trend = Math.random() > 0.5 ? "up" : "down";
    const percentage = Math.floor(Math.random() * 20) + 1;
    return { trend, percentage };
  };

  // Loading state with skeleton
  if (isLoading) {
    return (
      <Box>
        <Typography variant="h4" gutterBottom>
          Dashboard
        </Typography>
        <Grid container spacing={3} sx={{ mb: 4 }}>
          {[1, 2, 3, 4].map((i) => (
            <Grid item xs={12} sm={6} md={3} key={i}>
              <Card>
                <CardContent>
                  <Skeleton variant="text" width="60%" />
                  <Skeleton variant="text" width="40%" height={40} />
                  <Skeleton variant="text" width="50%" />
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Box>
    );
  }

  const statCards = [
    {
      title: "Total Users",
      value: userStats?.total || 0,
      subtitle: `${userStats?.active || 0} active`,
      icon: <PeopleIcon fontSize="large" />,
      color: "#1976d2",
      trend: calculateTrend(userStats?.total || 0),
    },
    {
      title: "Total Reports",
      value: reportStats?.total || 0,
      subtitle: `${reportStats?.by_status?.pending || 0} pending`,
      icon: <ReportsIcon fontSize="large" />,
      color: "#dc004e",
      trend: calculateTrend(reportStats?.total || 0),
    },
    {
      title: "Total Matches",
      value: matchStats?.total || 0,
      subtitle: `${matchStats?.confirmed || 0} confirmed`,
      icon: <MatchesIcon fontSize="large" />,
      color: "#9c27b0",
      trend: calculateTrend(matchStats?.total || 0),
    },
    {
      title: "New Users Today",
      value: userStats?.new_today || 0,
      subtitle: "Last 24 hours",
      icon: <CheckIcon fontSize="large" />,
      color: "#2e7d32",
      trend: calculateTrend(userStats?.new_today || 0),
    },
  ];

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statCards.map((card) => (
          <Grid item xs={12} sm={6} md={3} key={card.title}>
            <Card sx={{ height: "100%" }}>
              <CardContent>
                <Box
                  display="flex"
                  justifyContent="space-between"
                  alignItems="flex-start"
                >
                  <Box sx={{ flex: 1 }}>
                    <Typography
                      color="text.secondary"
                      gutterBottom
                      variant="body2"
                    >
                      {card.title}
                    </Typography>
                    <Typography variant="h4" sx={{ mb: 1 }}>
                      {card.value}
                    </Typography>
                    <Box display="flex" alignItems="center" gap={1}>
                      <Box
                        display="flex"
                        alignItems="center"
                        sx={{
                          color:
                            card.trend.trend === "up"
                              ? "success.main"
                              : "error.main",
                        }}
                      >
                        {card.trend.trend === "up" ? (
                          <TrendingUpIcon fontSize="small" />
                        ) : (
                          <TrendingDownIcon fontSize="small" />
                        )}
                        <Typography variant="caption" sx={{ ml: 0.5 }}>
                          {card.trend.percentage}%
                        </Typography>
                      </Box>
                      <Typography variant="caption" color="text.secondary">
                        {card.subtitle}
                      </Typography>
                    </Box>
                  </Box>
                  <Box
                    sx={{
                      color: card.color,
                      backgroundColor: `${card.color}15`,
                      borderRadius: 2,
                      p: 1,
                    }}
                  >
                    {card.icon}
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Grid container spacing={3}>
        {/* Reports Over Time - Line Chart */}
        <Grid item xs={12} lg={8}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Reports & Matches Trend (Last 7 Days)
            </Typography>
            <Box sx={{ width: "100%", height: 300, mt: 2 }}>
              <ResponsiveContainer>
                <AreaChart data={reportsOverTimeData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Area
                    type="monotone"
                    dataKey="reports"
                    stackId="1"
                    stroke="#1976d2"
                    fill="#1976d2"
                    fillOpacity={0.6}
                  />
                  <Area
                    type="monotone"
                    dataKey="matches"
                    stackId="2"
                    stroke="#2e7d32"
                    fill="#2e7d32"
                    fillOpacity={0.6}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </Box>
          </Paper>
        </Grid>

        {/* Recent Activity Feed */}
        <Grid item xs={12} lg={4}>
          <Paper sx={{ p: 3, height: "100%" }}>
            <Typography variant="h6" gutterBottom>
              Recent Activity
            </Typography>
            <List sx={{ mt: 2 }}>
              {recentActivity.map((activity) => {
                const getChipColor = (
                  type: string
                ): "success" | "primary" | "default" => {
                  if (type === "Match Confirmed") return "success";
                  if (type === "New Report") return "primary";
                  return "default";
                };

                return (
                  <Box key={activity.title + activity.time}>
                    <ListItem sx={{ px: 0 }}>
                      <ListItemText
                        disableTypography
                        primary={
                          <Box display="flex" alignItems="center" gap={1}>
                            <Chip
                              label={activity.type}
                              size="small"
                              color={getChipColor(activity.type)}
                            />
                          </Box>
                        }
                        secondary={
                          <Box sx={{ mt: 0.5 }}>
                            <Typography
                              variant="body2"
                              component="span"
                              display="block"
                            >
                              {activity.title}
                            </Typography>
                            <Typography
                              variant="caption"
                              color="text.secondary"
                              component="span"
                              display="block"
                            >
                              {activity.time}
                            </Typography>
                          </Box>
                        }
                      />
                    </ListItem>
                    {activity !== recentActivity[recentActivity.length - 1] && (
                      <Divider />
                    )}
                  </Box>
                );
              })}
            </List>
          </Paper>
        </Grid>

        {/* Category Distribution - Pie Chart */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Reports by Category
            </Typography>
            <Box sx={{ width: "100%", height: 300, mt: 2 }}>
              <ResponsiveContainer>
                <PieChart>
                  <Pie
                    data={categoryData}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percent }) =>
                      `${name}: ${(percent * 100).toFixed(0)}%`
                    }
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {categoryData.map((entry, index) => (
                      <Cell
                        key={`cell-${entry.name}`}
                        fill={COLORS[index % COLORS.length]}
                      />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </Box>
          </Paper>
        </Grid>

        {/* Match Status - Bar Chart */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Match Status Distribution
            </Typography>
            <Box sx={{ width: "100%", height: 300, mt: 2 }}>
              <ResponsiveContainer>
                <BarChart data={matchStatusData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="value" fill="#9c27b0" />
                </BarChart>
              </ResponsiveContainer>
            </Box>
          </Paper>
        </Grid>

        {/* Report Statistics by Type and Status */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Detailed Statistics
            </Typography>
            <Box sx={{ mt: 2 }}>
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <Typography
                    variant="body2"
                    color="text.secondary"
                    gutterBottom
                    sx={{ fontWeight: 600 }}
                  >
                    By Type
                  </Typography>
                  <Box sx={{ mt: 2 }}>
                    {reportStats?.by_type &&
                      Object.entries(reportStats.by_type).map(
                        ([type, count]) => (
                          <Box
                            key={type}
                            display="flex"
                            justifyContent="space-between"
                            alignItems="center"
                            sx={{ mb: 2 }}
                          >
                            <Box display="flex" alignItems="center" gap={1}>
                              <Box
                                sx={{
                                  width: 8,
                                  height: 8,
                                  borderRadius: "50%",
                                  bgcolor:
                                    type === "lost"
                                      ? "error.main"
                                      : "success.main",
                                }}
                              />
                              <Typography variant="body2">
                                {type.toUpperCase()}
                              </Typography>
                            </Box>
                            <Chip
                              label={count}
                              size="small"
                              color={type === "lost" ? "error" : "success"}
                              variant="outlined"
                            />
                          </Box>
                        )
                      )}
                  </Box>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography
                    variant="body2"
                    color="text.secondary"
                    gutterBottom
                    sx={{ fontWeight: 600 }}
                  >
                    By Status
                  </Typography>
                  <Box sx={{ mt: 2 }}>
                    {reportStats?.by_status &&
                      Object.entries(reportStats.by_status).map(
                        ([status, count]) => (
                          <Box
                            key={status}
                            display="flex"
                            justifyContent="space-between"
                            alignItems="center"
                            sx={{ mb: 2 }}
                          >
                            <Box display="flex" alignItems="center" gap={1}>
                              <Box
                                sx={{
                                  width: 8,
                                  height: 8,
                                  borderRadius: "50%",
                                  bgcolor: "primary.main",
                                }}
                              />
                              <Typography variant="body2">
                                {status.toUpperCase()}
                              </Typography>
                            </Box>
                            <Chip
                              label={count}
                              size="small"
                              variant="outlined"
                            />
                          </Box>
                        )
                      )}
                  </Box>
                </Grid>
              </Grid>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
