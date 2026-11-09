import { Box, Button, Paper, Typography } from '@mui/material';
import AssessmentRoundedIcon from '@mui/icons-material/AssessmentRounded';
import PeopleAltRoundedIcon from '@mui/icons-material/PeopleAltRounded';
import BusinessCenterRoundedIcon from '@mui/icons-material/BusinessCenterRounded';
import ArrowOutwardRoundedIcon from '@mui/icons-material/ArrowOutwardRounded';
import FlightTakeoffRoundedIcon from '@mui/icons-material/FlightTakeoffRounded';
import Inventory2OutlinedIcon from '@mui/icons-material/Inventory2Outlined';
import { Link } from 'react-router-dom';

const shortcuts = [
  {
    to: '/admin/tourists',
    eyebrow: 'УПРАВЛЕНИЕ ГРУППОЙ',
    title: 'Туристы',
    description: 'Карточки путешественников, категории поездок и документы.',
    action: 'Открыть список',
    icon: <PeopleAltRoundedIcon />,
    color: '#72e0cb',
  },
  {
    to: '/admin/operations',
    eyebrow: 'ЕЖЕДНЕВНАЯ РАБОТА',
    title: 'Операции и справочники',
    description: 'Рейсы, гостиницы, экскурсии, размещение, груз и финансы.',
    action: 'Перейти к операциям',
    icon: <BusinessCenterRoundedIcon />,
    color: '#f1c98d',
  },
  {
    to: '/admin/warehouse',
    eyebrow: 'ПРИЕМ И ОТПРАВКА',
    title: 'Склад и груз',
    description: 'Весовые ведомости, маркировка, упаковка, страховка и отправка по рейсам.',
    action: 'Открыть склад',
    icon: <Inventory2OutlinedIcon />,
    color: '#8ec5ff',
  },
  {
    to: '/admin/reports',
    eyebrow: 'АНАЛИТИКА И КОНТРОЛЬ',
    title: 'Центр отчетов',
    description: 'Отчеты по требованиям курсовой и сводка работы фирмы.',
    action: 'Сформировать отчет',
    icon: <AssessmentRoundedIcon />,
    color: '#a5b8ff',
  },
];

const AdminDashboard = () => (
  <Box sx={{ maxWidth: 1320, mx: 'auto' }}>
    <Paper
      elevation={0}
      className="admin-dashboard-hero reveal"
      sx={{
        position: 'relative',
        minHeight: { xs: 250, md: 300 },
        display: 'flex',
        alignItems: 'center',
        overflow: 'hidden',
        p: { xs: 3, sm: 4, md: 5 },
        border: '1px solid rgba(222,241,238,.1)',
        borderRadius: { xs: 4, md: 6 },
        background:
          'radial-gradient(ellipse at 86% 28%,rgba(114,224,203,.18),transparent 28%),linear-gradient(112deg,rgba(18,48,55,.98),rgba(12,31,39,.94) 58%,rgba(18,45,48,.84))',
        boxShadow: '0 26px 70px rgba(0,0,0,.24)',
      }}
    >
      <Box sx={{ position: 'absolute', right: { xs: -60, md: 55 }, top: { xs: 38, md: 28 }, color: 'rgba(144,230,212,.12)', transform: 'rotate(-15deg)' }}>
        <FlightTakeoffRoundedIcon sx={{ fontSize: { xs: 160, md: 245 } }} />
      </Box>
      <Box sx={{ position: 'relative', zIndex: 1, maxWidth: 700 }}>
        <Box className="eyebrow" sx={{ mb: 2 }}>Добро пожаловать в рабочее пространство</Box>
        <Typography variant="h2" sx={{ maxWidth: 700, fontSize: { xs: 34, sm: 43, md: 52 }, lineHeight: 1.08, mb: 1.75 }}>
          Каждая поездка — под контролем.
        </Typography>
        <Typography sx={{ maxWidth: 590, color: 'text.secondary', fontSize: { xs: 14, md: 16 }, lineHeight: 1.75 }}>
          Управляйте группами туристов, размещением, экскурсиями, багажом и финансовой отчетностью в единой системе.
        </Typography>
        <Button
          component={Link}
          to="/admin/reports"
          variant="contained"
          endIcon={<ArrowOutwardRoundedIcon />}
          className="soft-button"
          sx={{ mt: 3, minHeight: 48, color: '#08211f', boxShadow: '0 10px 24px rgba(72,202,180,.15)' }}
        >
          Перейти к отчетам
        </Button>
      </Box>
    </Paper>

    <Box sx={{ mt: { xs: 4, md: 5 }, mb: 2.5, display: 'flex', justifyContent: 'space-between', alignItems: 'end', gap: 2, flexWrap: 'wrap' }}>
      <Box>
        <Box className="eyebrow" sx={{ mb: 1 }}>Быстрый доступ</Box>
        <Typography variant="h4" sx={{ fontSize: { xs: 25, md: 31 } }}>С чего начнем?</Typography>
      </Box>
      <Typography variant="body2" sx={{ color: 'text.secondary' }}>Основные разделы представительства</Typography>
    </Box>

    <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(2, 1fr)', xl: 'repeat(4, 1fr)' }, gap: 2 }}>
      {shortcuts.map((shortcut, index) => (
        <Paper
          key={shortcut.to}
          component={Link}
          to={shortcut.to}
          elevation={0}
          className={`surface-card reveal reveal-delay-${index + 1}`}
          sx={{ minHeight: 245, p: { xs: 2.5, md: 3 }, display: 'flex', flexDirection: 'column', textDecoration: 'none' }}
        >
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', mb: 2.5 }}>
            <Box sx={{ width: 48, height: 48, display: 'grid', placeItems: 'center', borderRadius: '16px', color: shortcut.color, bgcolor: `${shortcut.color}16`, border: `1px solid ${shortcut.color}2b`, '& svg': { fontSize: 25 } }}>
              {shortcut.icon}
            </Box>
            <Typography variant="caption" sx={{ color: 'text.secondary', letterSpacing: '.1em', fontWeight: 700 }}>
              {shortcut.eyebrow}
            </Typography>
          </Box>
          <Typography variant="h6" sx={{ fontWeight: 750, mb: 1 }}>{shortcut.title}</Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', lineHeight: 1.7, mb: 2, flex: 1 }}>
            {shortcut.description}
          </Typography>
          <Box className="shortcut-action" sx={{ display: 'flex', alignItems: 'center', gap: 0.75, color: shortcut.color, fontSize: 13, fontWeight: 750 }}>
            {shortcut.action}
            <ArrowOutwardRoundedIcon sx={{ fontSize: 17, transition: 'transform 180ms ease', '.surface-card:hover &': { transform: 'translate(3px,-3px)' } }} />
          </Box>
        </Paper>
      ))}
    </Box>
  </Box>
);

export default AdminDashboard;
