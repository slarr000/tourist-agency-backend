import React, { useEffect, useMemo, useState } from 'react';
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
  NavLink,
  useLocation,
} from 'react-router-dom';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Chip,
  CircularProgress,
  CssBaseline,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  ThemeProvider,
  Typography,
  createTheme,
  type PaletteMode,
} from '@mui/material';
import DashboardRoundedIcon from '@mui/icons-material/DashboardRounded';
import DescriptionRoundedIcon from '@mui/icons-material/DescriptionRounded';
import ManageAccountsRoundedIcon from '@mui/icons-material/ManageAccountsRounded';
import BusinessCenterRoundedIcon from '@mui/icons-material/BusinessCenterRounded';
import FlightTakeoffRoundedIcon from '@mui/icons-material/FlightTakeoffRounded';
import Inventory2OutlinedIcon from '@mui/icons-material/Inventory2Outlined';
import LogoutRoundedIcon from '@mui/icons-material/LogoutRounded';
import Landing from './pages/Landing';
import AdminLogin from './pages/AdminLogin';
import AdminDashboard from './pages/AdminDashboard';
import TouristManagement from './pages/TouristManagement';
import ReportCenter from './pages/ReportCenter';
import OperationsManagement from './pages/OperationsManagement';
import Warehouse from './pages/Warehouse';
import ThemeToggle, { type ThemeMode } from './components/ThemeToggle';
import { ApiError, apiRequest } from './lib/api';

interface EmployeeIdentity {
  login: string;
  role: string;
}

type AuthStatus = 'unknown' | 'checking' | 'authenticated' | 'anonymous' | 'unavailable';

const navigation = [
  { label: 'Обзор', to: '/admin', icon: <DashboardRoundedIcon /> },
  { label: 'Туристы', to: '/admin/tourists', icon: <ManageAccountsRoundedIcon /> },
  { label: 'Операции', to: '/admin/operations', icon: <BusinessCenterRoundedIcon /> },
  { label: 'Склад', to: '/admin/warehouse', icon: <Inventory2OutlinedIcon /> },
  { label: 'Отчеты', to: '/admin/reports', icon: <DescriptionRoundedIcon /> },
];

const THEME_STORAGE_KEY = 'is-tour-theme';

const createAppTheme = (mode: PaletteMode) => createTheme({
  palette: {
    mode,
    primary: mode === 'dark'
      ? { main: '#72e0cb', light: '#a3f2e3', dark: '#2fb9a2', contrastText: '#08211f' }
      : { main: '#087f72', light: '#2b9e8e', dark: '#06665c', contrastText: '#ffffff' },
    secondary: { main: mode === 'dark' ? '#f1c98d' : '#9b681f' },
    background: mode === 'dark'
      ? { default: '#07151b', paper: '#10262e' }
      : { default: '#f3f7f6', paper: '#ffffff' },
    text: mode === 'dark'
      ? { primary: '#f3f6f7', secondary: '#9aadb1' }
      : { primary: '#172c30', secondary: '#5f7478' },
    divider: mode === 'dark' ? 'rgba(222, 241, 238, 0.1)' : 'rgba(25, 65, 68, 0.14)',
  },
  shape: { borderRadius: 16 },
  typography: {
    fontFamily: '"Inter", "Segoe UI", "Helvetica Neue", sans-serif',
    h1: { fontWeight: 800, letterSpacing: '-0.055em' },
    h2: { fontWeight: 800, letterSpacing: '-0.045em' },
    h3: { fontWeight: 750, letterSpacing: '-0.04em' },
    h4: { fontWeight: 750, letterSpacing: '-0.035em' },
    h5: { fontWeight: 700, letterSpacing: '-0.025em' },
    button: { fontWeight: 700, textTransform: 'none' },
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: { backgroundColor: mode === 'dark' ? '#07151b' : '#f3f7f6' },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: { backgroundImage: 'none' },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: { borderRadius: 14, paddingInline: 18 },
      },
    },
    MuiOutlinedInput: {
      styleOverrides: {
        root: {
          borderRadius: 14,
          '& fieldset': { borderColor: mode === 'dark' ? 'rgba(222, 241, 238, 0.16)' : 'rgba(25, 65, 68, 0.2)' },
          '&:hover fieldset': { borderColor: mode === 'dark' ? 'rgba(114, 224, 203, 0.5)' : 'rgba(8, 127, 114, 0.55)' },
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        root: { borderColor: 'rgba(222, 241, 238, 0.08)' },
      },
    },
  },
});

function AnimatedPage({ children }: { children: React.ReactNode }) {
  const { pathname } = useLocation();
  return <Box key={pathname} className="page-enter">{children}</Box>;
}

function AdminLayout({
  children,
  themeMode,
  onToggleTheme,
  employee,
  onLogout,
}: {
  children: React.ReactNode;
  themeMode: ThemeMode;
  onToggleTheme: () => void;
  employee: EmployeeIdentity;
  onLogout: () => void;
}) {
  const location = useLocation();
  const currentPage = navigation.find((item) =>
    item.to === '/admin'
      ? location.pathname === item.to
      : location.pathname.startsWith(item.to),
  )?.label ?? 'Рабочее пространство';

  const navItems = navigation.map((item) => {
    const active = item.to === '/admin'
      ? location.pathname === item.to
      : location.pathname.startsWith(item.to);

    return (
      <ListItem key={item.to} disablePadding>
        <ListItemButton
          component={NavLink}
          to={item.to}
          end={item.to === '/admin'}
          className={`admin-nav-link${active ? ' is-active' : ''}`}
          sx={{ minHeight: 48, mb: 0.5, px: 1.5 }}
        >
          <ListItemIcon sx={{ minWidth: 38, color: active ? 'primary.main' : 'text.secondary' }}>
            {item.icon}
          </ListItemIcon>
          <ListItemText primary={
            <Typography sx={{ fontSize: 13, fontWeight: active ? 700 : 550, color: active ? 'text.primary' : 'text.secondary' }}>
              {item.label}
            </Typography>
          } />
        </ListItemButton>
      </ListItem>
    );
  });

  return (
    <Box className="admin-shell">
      <Box component="nav" className="admin-sidebar" aria-label="Основная навигация">
        <Box className="admin-sidebar-brand" sx={{ display: 'flex', alignItems: 'center', gap: 1.5, p: 2.5 }}>
          <Avatar
            variant="rounded"
            sx={{
              width: 42,
              height: 42,
              borderRadius: '14px',
              color: '#06221f',
              background: 'linear-gradient(145deg, #a4f3e5, #46c5b0)',
              boxShadow: '0 8px 26px rgba(72, 202, 180, 0.22)',
            }}
          >
            <FlightTakeoffRoundedIcon />
          </Avatar>
          <Box>
            <Typography sx={{ fontWeight: 800, letterSpacing: '-0.04em', lineHeight: 1.1 }}>
              IS Tour
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary', letterSpacing: '0.08em' }}>
              ПРЕДСТАВИТЕЛЬСТВО
            </Typography>
          </Box>
        </Box>

        <Box className="admin-sidebar-groups" sx={{ px: 1.5, pt: 1 }}>
          <Typography variant="overline" sx={{ px: 1.5, color: 'text.secondary', fontSize: 10, fontWeight: 800, letterSpacing: '0.15em' }}>
            РАБОЧЕЕ ПРОСТРАНСТВО
          </Typography>
          <List sx={{ pt: 1 }}>{navItems}</List>
        </Box>

        <Box sx={{ flex: 1 }} />
        <Box className="admin-sidebar-groups admin-system-status" sx={{ m: 1.5, p: 1.5, border: '1px solid var(--color-line)', borderRadius: 3, background: 'var(--color-bg-soft)' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.75 }}>
            <Box sx={{ width: 7, height: 7, borderRadius: '50%', bgcolor: '#72e0cb', boxShadow: '0 0 12px rgba(114,224,203,.8)' }} />
            <Typography variant="caption" sx={{ color: 'text.primary', fontWeight: 700 }}>Система готова</Typography>
          </Box>
          <Typography variant="caption" sx={{ color: 'text.secondary', lineHeight: 1.5 }}>
            Управление поездками, документами и отчетностью
          </Typography>
        </Box>

        <Box className="admin-mobile-nav">{navItems}</Box>
      </Box>

      <Box className="admin-main">
        <Box className="admin-topbar" sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2, px: { xs: 1.5, sm: 2.5 }, py: 1.25 }}>
          <Box sx={{ minWidth: 0 }}>
            <Typography variant="caption" sx={{ color: 'text.secondary', display: { xs: 'none', sm: 'block' } }}>
              Туристическая информационная система
            </Typography>
            <Typography variant="subtitle1" sx={{ fontWeight: 750 }}>{currentPage}</Typography>
          </Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: { xs: 0.75, sm: 1.5 } }}>
            <ThemeToggle mode={themeMode} onToggle={onToggleTheme} />
            <Chip
              size="small"
              label={employee.login}
              sx={{ height: 34, border: '1px solid rgba(222,241,238,.1)', bgcolor: 'rgba(238,250,245,.035)', '& .MuiChip-label': { px: 1, fontSize: 12, fontWeight: 700 } }}
            />
            <Button
              color="inherit"
              size="small"
              startIcon={<LogoutRoundedIcon />}
              onClick={onLogout}
              sx={{ minWidth: { xs: 40, sm: 'auto' }, '& .MuiButton-startIcon': { mr: { xs: 0, sm: 1 } } }}
              aria-label="Выйти из системы"
            >
              <Box component="span" sx={{ display: { xs: 'none', sm: 'inline' } }}>Выйти</Box>
            </Button>
            <Chip
              size="small"
              label="ВНУТРЕННЯЯ СИСТЕМА"
              sx={{ height: 34, border: '1px solid rgba(222,241,238,.1)', bgcolor: 'rgba(238,250,245,.035)', '& .MuiChip-label': { px: 1, fontSize: 12, fontWeight: 700 } }}
            />
          </Box>
        </Box>
        <Box component="main" className="admin-content">
          <AnimatedPage>{children}</AnimatedPage>
        </Box>
      </Box>
    </Box>
  );
}

function AdminGate({
  status,
  error,
  onCheck,
  onRetry,
  children,
}: {
  status: AuthStatus;
  error: string;
  onCheck: () => void;
  onRetry: () => void;
  children: React.ReactNode;
}) {
  const location = useLocation();

  React.useEffect(() => {
    if (status === 'unknown') onCheck();
  }, [status, onCheck]);

  if (status === 'unknown' || status === 'checking') {
    return <Box sx={{ minHeight: '100vh', display: 'grid', placeItems: 'center' }}><CircularProgress /></Box>;
  }

  if (status === 'unavailable') {
    return (
      <Box sx={{ maxWidth: 560, mx: 'auto', p: 3, mt: 8 }}>
        <Alert
          severity="error"
          action={<Button color="inherit" onClick={onRetry}>Повторить</Button>}
        >
          Не удалось проверить сессию сотрудника: {error}
        </Alert>
      </Box>
    );
  }

  if (status === 'anonymous') {
    return <Navigate to="/admin/login" replace state={{ from: location }} />;
  }

  return children;
}

function App() {
  const [themeMode, setThemeMode] = useState<ThemeMode>(() => {
    const storedTheme = localStorage.getItem(THEME_STORAGE_KEY);
    return storedTheme === 'light' ? 'light' : 'dark';
  });
  const theme = useMemo(() => createAppTheme(themeMode), [themeMode]);
  const [employee, setEmployee] = useState<EmployeeIdentity | null>(null);
  const [authStatus, setAuthStatus] = useState<AuthStatus>('unknown');
  const [authError, setAuthError] = useState('');

  const checkSession = React.useCallback(async () => {
    setAuthStatus('checking');
    setAuthError('');
    try {
      const currentEmployee = await apiRequest<EmployeeIdentity>('/api/Auth/me');
      setEmployee(currentEmployee);
      setAuthStatus('authenticated');
    } catch (error) {
      setEmployee(null);
      if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
        setAuthStatus('anonymous');
      } else {
        setAuthError(error instanceof Error ? error.message : 'Сервер авторизации недоступен.');
        setAuthStatus('unavailable');
      }
    }
  }, []);

  useEffect(() => {
    document.documentElement.dataset.theme = themeMode;
    localStorage.setItem(THEME_STORAGE_KEY, themeMode);
  }, [themeMode]);

  const toggleTheme = () => setThemeMode((currentMode) => currentMode === 'dark' ? 'light' : 'dark');

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Routes>
          <Route path="/" element={<Landing themeMode={themeMode} onToggleTheme={toggleTheme} />} />
          <Route
            path="/admin/login"
            element={
              <AdminLogin
                themeMode={themeMode}
                onToggleTheme={toggleTheme}
                initialError={authError}
                onLogin={(signedInEmployee) => {
                  setEmployee(signedInEmployee);
                  setAuthError('');
                  setAuthStatus('authenticated');
                }}
              />
            }
          />
          <Route
            path="/admin/*"
            element={
              <AdminGate
                status={authStatus}
                error={authError}
                onCheck={checkSession}
                onRetry={() => void checkSession()}
              >
                {employee && (
                  <AdminLayout
                    themeMode={themeMode}
                    onToggleTheme={toggleTheme}
                    employee={employee}
                    onLogout={() => {
                      void apiRequest<void>('/api/Auth/logout', { method: 'POST' })
                        .catch((error: unknown) => {
                          setAuthError(error instanceof Error ? error.message : 'Не удалось завершить сеанс на сервере.');
                        })
                        .finally(() => {
                          setEmployee(null);
                          setAuthStatus('anonymous');
                        });
                    }}
                  >
                    <Routes>
                      <Route path="/" element={<AdminDashboard />} />
                      <Route path="tourists" element={<TouristManagement />} />
                      <Route path="operations" element={<OperationsManagement />} />
                      <Route path="warehouse" element={<Warehouse />} />
                      <Route path="reports" element={<ReportCenter />} />
                      <Route path="*" element={<Navigate to="/admin/reports" replace />} />
                    </Routes>
                  </AdminLayout>
                )}
              </AdminGate>
            }
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </ThemeProvider>
  );
}

export default App;
