import { useState, useMemo } from "react";
import { Outlet, Link, useLocation } from "react-router-dom";
import {
  AppBar,
  Box,
  Drawer,
  Toolbar,
  Typography,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  IconButton,
  Divider,
  Breadcrumbs,
  Menu,
  MenuItem,
  Avatar,
  Badge,
  InputBase,
  Tooltip,
  useTheme,
  alpha,
} from "@mui/material";
import {
  Dashboard as DashboardIcon,
  Description as ReportsIcon,
  Link as MatchesIcon,
  People as UsersIcon,
  History as AuditIcon,
  Settings as SystemIcon,
  Logout as LogoutIcon,
  Menu as MenuIcon,
  ChevronLeft as ChevronLeftIcon,
  Notifications as NotificationsIcon,
  Search as SearchIcon,
  Brightness4 as DarkModeIcon,
  Brightness7 as LightModeIcon,
  NavigateNext as NavigateNextIcon,
  AccountCircle as AccountCircleIcon,
} from "@mui/icons-material";
import { useAuthStore } from "@/stores/authStore";

const drawerWidthExpanded = 280;
const drawerWidthCollapsed = 72;

const menuItems = [
  { text: "Dashboard", icon: <DashboardIcon />, path: "/" },
  { text: "Reports", icon: <ReportsIcon />, path: "/reports" },
  { text: "Matches", icon: <MatchesIcon />, path: "/matches" },
  { text: "Users", icon: <UsersIcon />, path: "/users" },
  { text: "Audit Log", icon: <AuditIcon />, path: "/audit" },
  { text: "System", icon: <SystemIcon />, path: "/system" },
];

// Helper function to generate breadcrumbs from path
const getBreadcrumbs = (pathname: string) => {
  const paths = pathname.split("/").filter(Boolean);
  const breadcrumbs = [{ label: "Dashboard", path: "/" }];

  paths.forEach((path, index) => {
    const fullPath = "/" + paths.slice(0, index + 1).join("/");
    const label = path.charAt(0).toUpperCase() + path.slice(1);
    breadcrumbs.push({ label, path: fullPath });
  });

  return breadcrumbs;
};

export default function Layout() {
  const location = useLocation();
  const { user, logout } = useAuthStore();
  const theme = useTheme();

  // State management
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [darkMode, setDarkMode] = useState(false);
  const [anchorElUser, setAnchorElUser] = useState<null | HTMLElement>(null);
  const [searchQuery, setSearchQuery] = useState("");

  const drawerWidth = sidebarOpen ? drawerWidthExpanded : drawerWidthCollapsed;
  const breadcrumbs = useMemo(
    () => getBreadcrumbs(location.pathname),
    [location.pathname]
  );

  const handleUserMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorElUser(event.currentTarget);
  };

  const handleUserMenuClose = () => {
    setAnchorElUser(null);
  };

  const handleLogout = () => {
    handleUserMenuClose();
    logout();
  };

  const toggleDarkMode = () => {
    setDarkMode(!darkMode);
    // TODO: Implement actual dark mode theme switching
  };

  return (
    <Box sx={{ display: "flex" }}>
      <AppBar
        position="fixed"
        sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}
      >
        <Toolbar>
          {/* Menu toggle button */}
          <IconButton
            color="inherit"
            edge="start"
            onClick={() => setSidebarOpen(!sidebarOpen)}
            sx={{ mr: 2 }}
          >
            {sidebarOpen ? <ChevronLeftIcon /> : <MenuIcon />}
          </IconButton>

          <Typography variant="h6" noWrap component="div">
            Lost & Found Admin
          </Typography>

          {/* Search Bar */}
          <Box
            sx={{
              display: { xs: "none", md: "flex" },
              alignItems: "center",
              ml: 4,
              backgroundColor: alpha(theme.palette.common.white, 0.15),
              "&:hover": {
                backgroundColor: alpha(theme.palette.common.white, 0.25),
              },
              borderRadius: 1,
              px: 2,
              py: 0.5,
              minWidth: 300,
            }}
          >
            <SearchIcon sx={{ mr: 1 }} />
            <InputBase
              placeholder="Search reports, users..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              sx={{ color: "inherit", width: "100%" }}
            />
          </Box>

          <Box sx={{ flexGrow: 1 }} />

          {/* Dark Mode Toggle */}
          <Tooltip title={darkMode ? "Light Mode" : "Dark Mode"}>
            <IconButton color="inherit" onClick={toggleDarkMode}>
              {darkMode ? <LightModeIcon /> : <DarkModeIcon />}
            </IconButton>
          </Tooltip>

          {/* Notifications */}
          <Tooltip title="Notifications">
            <IconButton color="inherit">
              <Badge badgeContent={3} color="error">
                <NotificationsIcon />
              </Badge>
            </IconButton>
          </Tooltip>

          {/* User Profile Menu */}
          <Tooltip title="Account settings">
            <IconButton onClick={handleUserMenuOpen} sx={{ ml: 1 }}>
              <Avatar
                sx={{
                  width: 32,
                  height: 32,
                  bgcolor: "secondary.main",
                }}
              >
                {user?.display_name?.[0] || user?.email?.[0] || "U"}
              </Avatar>
            </IconButton>
          </Tooltip>
          <Menu
            anchorEl={anchorElUser}
            open={Boolean(anchorElUser)}
            onClose={handleUserMenuClose}
            onClick={handleUserMenuClose}
            sx={{ mt: 1 }}
          >
            <MenuItem disabled>
              <Typography variant="body2" color="text.secondary">
                {user?.email}
              </Typography>
            </MenuItem>
            <Divider />
            <MenuItem onClick={handleUserMenuClose}>
              <AccountCircleIcon sx={{ mr: 1 }} fontSize="small" />
              Profile
            </MenuItem>
            <MenuItem onClick={handleLogout}>
              <LogoutIcon sx={{ mr: 1 }} fontSize="small" />
              Logout
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>

      <Drawer
        variant="permanent"
        sx={{
          width: drawerWidth,
          flexShrink: 0,
          transition: (theme) =>
            theme.transitions.create("width", {
              easing: theme.transitions.easing.sharp,
              duration: theme.transitions.duration.enteringScreen,
            }),
          [`& .MuiDrawer-paper`]: {
            width: drawerWidth,
            boxSizing: "border-box",
            transition: (theme) =>
              theme.transitions.create("width", {
                easing: theme.transitions.easing.sharp,
                duration: theme.transitions.duration.enteringScreen,
              }),
            overflowX: "hidden",
          },
        }}
      >
        <Toolbar />
        <Box sx={{ overflow: "auto" }}>
          <List>
            {menuItems.map((item) => (
              <ListItem key={item.text} disablePadding>
                <Tooltip
                  title={!sidebarOpen ? item.text : ""}
                  placement="right"
                >
                  <ListItemButton
                    component={Link}
                    to={item.path}
                    selected={location.pathname === item.path}
                    sx={{
                      minHeight: 48,
                      justifyContent: sidebarOpen ? "initial" : "center",
                      px: 2.5,
                    }}
                  >
                    <ListItemIcon
                      sx={{
                        minWidth: 0,
                        mr: sidebarOpen ? 3 : "auto",
                        justifyContent: "center",
                      }}
                    >
                      {item.icon}
                    </ListItemIcon>
                    {sidebarOpen && <ListItemText primary={item.text} />}
                  </ListItemButton>
                </Tooltip>
              </ListItem>
            ))}
          </List>
          <Divider />
        </Box>
      </Drawer>

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          transition: (theme) =>
            theme.transitions.create("margin", {
              easing: theme.transitions.easing.sharp,
              duration: theme.transitions.duration.enteringScreen,
            }),
        }}
      >
        <Toolbar />

        {/* Breadcrumb Navigation */}
        <Box sx={{ mb: 3 }}>
          <Breadcrumbs
            separator={<NavigateNextIcon fontSize="small" />}
            aria-label="breadcrumb"
          >
            {breadcrumbs.map((crumb, index) => {
              const isLast = index === breadcrumbs.length - 1;
              return isLast ? (
                <Typography key={crumb.path} color="text.primary">
                  {crumb.label}
                </Typography>
              ) : (
                <Link
                  key={crumb.path}
                  to={crumb.path}
                  style={{
                    textDecoration: "none",
                    color: "inherit",
                  }}
                >
                  <Typography
                    color="text.secondary"
                    sx={{
                      "&:hover": {
                        textDecoration: "underline",
                      },
                    }}
                  >
                    {crumb.label}
                  </Typography>
                </Link>
              );
            })}
          </Breadcrumbs>
        </Box>

        <Outlet />
      </Box>
    </Box>
  );
}
