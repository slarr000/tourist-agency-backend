import { Box, Button, Container, Paper, Typography } from '@mui/material';
import { Link } from 'react-router-dom';
import FlightTakeoffRoundedIcon from '@mui/icons-material/FlightTakeoffRounded';
import ExploreRoundedIcon from '@mui/icons-material/ExploreRounded';
import LuggageRoundedIcon from '@mui/icons-material/LuggageRounded';
import HotelRoundedIcon from '@mui/icons-material/HotelRounded';
import ArrowOutwardRoundedIcon from '@mui/icons-material/ArrowOutwardRounded';
import VerifiedRoundedIcon from '@mui/icons-material/VerifiedRounded';
import SouthRoundedIcon from '@mui/icons-material/SouthRounded';
import ThemeToggle, { type ThemeMode } from '../components/ThemeToggle';

interface LandingProps {
  themeMode: ThemeMode;
  onToggleTheme: () => void;
}

const features = [
  {
    icon: <ExploreRoundedIcon />,
    number: '01',
    title: 'Туристы и группы',
    description: 'Ведите карточки туристов, категории, документы и состав поездок в едином рабочем пространстве.',
    accent: '#72e0cb',
  },
  {
    icon: <HotelRoundedIcon />,
    number: '02',
    title: 'Операции представительства',
    description: 'Управляйте размещением, рейсами, экскурсиями, грузом и финансовыми операциями.',
    accent: '#f1c98d',
  },
  {
    icon: <LuggageRoundedIcon />,
    number: '03',
    title: 'Отчеты и аналитика',
    description: 'Формируйте отчеты по требованиям варианта, анализируйте показатели и экспортируйте результаты.',
    accent: '#a5b8ff',
  },
];

const Landing = ({ themeMode, onToggleTheme }: LandingProps) => (
  <Box sx={{ minHeight: '100vh', overflow: 'hidden' }}>
    <Box
      component="header"
      sx={{
        position: 'sticky',
        top: 0,
        zIndex: 30,
        borderBottom: '1px solid var(--color-line)',
        background: 'var(--color-surface)',
        backdropFilter: 'blur(22px)',
      }}
    >
      <Container maxWidth="lg">
        <Box sx={{ minHeight: 76, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
          <Box component={Link} to="/" sx={{ display: 'inline-flex', alignItems: 'center', gap: 1.25 }}>
            <Box sx={{ display: 'grid', placeItems: 'center', width: 42, height: 42, borderRadius: '14px', color: '#06221f', background: 'linear-gradient(145deg,#a4f3e5,#46c5b0)', boxShadow: '0 8px 26px rgba(72,202,180,.2)' }}>
              <FlightTakeoffRoundedIcon />
            </Box>
            <Box>
              <Typography sx={{ fontWeight: 850, fontSize: 18, letterSpacing: '-.045em', lineHeight: 1.1 }}>IS Tour</Typography>
              <Typography sx={{ color: 'text.secondary', fontSize: 10, letterSpacing: '.13em' }}>РАБОЧАЯ СИСТЕМА</Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: { xs: 1, sm: 2.5 } }}>
            <Button
              component="a"
              href="#about"
              color="inherit"
              sx={{ display: { xs: 'none', sm: 'inline-flex' }, color: 'text.secondary', '&:hover': { color: 'text.primary', bgcolor: 'rgba(255,255,255,.04)' } }}
            >
              О системе
            </Button>
            <ThemeToggle mode={themeMode} onToggle={onToggleTheme} />
            <Button
              component={Link}
              to="/admin"
              variant="outlined"
              endIcon={<ArrowOutwardRoundedIcon />}
              className="soft-button"
              sx={{ minHeight: 44, borderColor: 'var(--color-line)', color: 'text.primary', '&:hover': { borderColor: 'primary.main', bgcolor: 'rgba(114,224,203,.08)' } }}
            >
              Открыть админку
            </Button>
          </Box>
        </Box>
      </Container>
    </Box>

    <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 1, pt: { xs: 5, md: 9 }, pb: { xs: 7, md: 10 } }}>
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1.02fr .98fr' }, alignItems: 'center', gap: { xs: 5, md: 7 } }}>
        <Box className="reveal">
          <Box className="eyebrow" sx={{ mb: 3 }}>Рабочее пространство туристического представительства</Box>
          <Typography
            variant="h1"
            sx={{
              maxWidth: 700,
              fontSize: { xs: '3.25rem', sm: '4.3rem', md: '5.1rem' },
              lineHeight: { xs: 1.02, md: 1.01 },
              mb: 2.5,
            }}
          >
            Все поездки
            <br />
            <Box
              component="span"
              className="hero-title-accent"
              sx={{
                color: 'transparent',
                background: 'linear-gradient(100deg,#a4f3e5 4%,#72e0cb 48%,#f1c98d 100%)',
                backgroundClip: 'text',
                WebkitBackgroundClip: 'text',
              }}
            >
              под контролем.
            </Box>
          </Typography>
          <Typography sx={{ maxWidth: 570, color: 'text.secondary', fontSize: { xs: 16, md: 18 }, lineHeight: 1.8 }}>
            Управляйте туристами, документами, размещением, экскурсиями и грузом в одной информационной системе.
          </Typography>

          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1.5, mt: 4 }}>
            <Button
              component={Link}
              to="/admin"
              variant="contained"
              endIcon={<ArrowOutwardRoundedIcon />}
              className="soft-button"
              sx={{
                minHeight: 54,
                px: 3,
                color: '#08211f',
                background: 'linear-gradient(115deg,#a4f3e5,#72e0cb)',
                boxShadow: '0 12px 32px rgba(72,202,180,.2)',
                '&:hover': { background: 'linear-gradient(115deg,#b7f9ec,#84ead6)', boxShadow: '0 16px 38px rgba(72,202,180,.3)' },
              }}
            >
              Перейти в админ-панель
            </Button>
            <Button
              component="a"
              href="#about"
              variant="outlined"
              endIcon={<SouthRoundedIcon />}
              className="soft-button"
              sx={{ minHeight: 54, px: 2.5, borderColor: 'var(--color-line)', color: 'text.primary', '&:hover': { borderColor: 'primary.main', bgcolor: 'rgba(255,255,255,.035)' } }}
            >
              Узнать больше
            </Button>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.25, mt: 4.5, color: 'text.secondary' }}>
            <VerifiedRoundedIcon sx={{ color: 'primary.main', fontSize: 19 }} />
            <Typography variant="body2">Единое рабочее место для сотрудников представительства</Typography>
          </Box>
        </Box>

        <Box className="reveal reveal-delay-2" sx={{ position: 'relative' }}>
          <Box sx={{ position: 'absolute', inset: '12% -6% -8% 12%', borderRadius: '50%', background: 'rgba(55,164,151,.14)', filter: 'blur(55px)' }} />
          <Box className="hero-visual">
            <Box className="hero-orbit float-slower" />
            <Box className="hero-route">
              <Box className="hero-route-dot float-slow" />
            </Box>
            <Box className="float-slow" sx={{ position: 'absolute', top: '18%', left: '12%', width: 70, height: 70, display: 'grid', placeItems: 'center', borderRadius: '24px', color: '#eafbf3', background: 'rgba(8,31,37,.38)', border: '1px solid rgba(221,246,234,.22)', backdropFilter: 'blur(10px)', transform: 'rotate(-10deg)' }}>
              <FlightTakeoffRoundedIcon sx={{ fontSize: 34 }} />
            </Box>
            <Box className="float-slower" sx={{ position: 'absolute', top: '24%', right: '16%', px: 1.5, py: 1, borderRadius: 3, color: '#f8ead2', border: '1px solid rgba(248,234,210,.26)', background: 'rgba(7,24,31,.32)', backdropFilter: 'blur(12px)' }}>
              <Typography variant="caption" sx={{ fontWeight: 700, letterSpacing: '.12em' }}>ТУРИСТЫ · РЕЙСЫ · ОТЧЕТЫ</Typography>
            </Box>
            <Box className="hero-stamp">
              <Box sx={{ width: 38, height: 38, display: 'grid', placeItems: 'center', borderRadius: '13px', color: '#08211f', bgcolor: 'primary.main' }}>
                <ExploreRoundedIcon fontSize="small" />
              </Box>
              <Box>
                <Typography variant="caption" sx={{ display: 'block', color: 'rgba(243,246,247,.66)' }}>РАБОЧИЙ ПРОЦЕСС</Typography>
                <Typography variant="body2" sx={{ fontWeight: 750 }}>От заявки до отчета</Typography>
              </Box>
            </Box>
          </Box>
          <Typography sx={{ mt: 1.5, textAlign: 'right', color: 'rgba(224,240,235,.42)', fontSize: 11, letterSpacing: '.08em' }}>
            ИНФОРМАЦИОННАЯ СИСТЕМА IS TOUR
          </Typography>
        </Box>
      </Box>

      <Box id="about" sx={{ pt: { xs: 8, md: 12 }, scrollMarginTop: 110 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'end', gap: 3, mb: 3.5, flexWrap: 'wrap' }}>
          <Box>
            <Box className="eyebrow" sx={{ mb: 1.5 }}>Инструменты сотрудников</Box>
            <Typography variant="h3" sx={{ fontSize: { xs: 30, md: 40 } }}>Все задачи представительства — в одном месте</Typography>
          </Box>
          <Typography sx={{ maxWidth: 390, color: 'text.secondary', lineHeight: 1.7 }}>
            Ведите ежедневные операции и быстро получайте актуальную информацию по группам и поездкам.
          </Typography>
        </Box>

        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(3, 1fr)' }, gap: 2 }}>
          {features.map((feature, index) => (
            <Paper
              key={feature.number}
              elevation={0}
              className={`surface-card reveal reveal-delay-${index + 1}`}
              sx={{ minHeight: 230, p: { xs: 2.5, md: 3 }, position: 'relative', overflow: 'hidden' }}
            >
              <Box sx={{ position: 'absolute', top: 14, right: 20, color: 'rgba(238,250,245,.08)', fontSize: 48, fontWeight: 850, letterSpacing: '-.08em' }}>
                {feature.number}
              </Box>
              <Box sx={{ width: 48, height: 48, display: 'grid', placeItems: 'center', mb: 2.5, borderRadius: '16px', color: feature.accent, background: `${feature.accent}18`, border: `1px solid ${feature.accent}2e`, '& svg': { fontSize: 25 } }}>
                {feature.icon}
              </Box>
              <Typography variant="h6" sx={{ fontWeight: 750, mb: 1 }}>{feature.title}</Typography>
              <Typography variant="body2" sx={{ color: 'text.secondary', lineHeight: 1.75, maxWidth: 340 }}>
                {feature.description}
              </Typography>
            </Paper>
          ))}
        </Box>
      </Box>

      <Box
        sx={{
          mt: { xs: 7, md: 10 },
          p: { xs: 3, md: 4 },
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          gap: 3,
          flexWrap: 'wrap',
          border: '1px solid rgba(114,224,203,.18)',
          borderRadius: { xs: 4, md: 6 },
          background: 'linear-gradient(110deg,rgba(39,112,105,.26),rgba(16,38,46,.7) 58%,rgba(113,81,48,.15))',
        }}
      >
        <Box sx={{ maxWidth: 600 }}>
          <Typography variant="h4" sx={{ mb: 1 }}>Готовы к работе?</Typography>
          <Typography sx={{ color: 'text.secondary', lineHeight: 1.7 }}>Откройте панель управления туристами, операциями и отчетами.</Typography>
        </Box>
        <Button component={Link} to="/admin" variant="contained" endIcon={<ArrowOutwardRoundedIcon />} className="soft-button" sx={{ minHeight: 50, color: '#08211f' }}>
          Открыть рабочее место
        </Button>
      </Box>

      <Box component="footer" sx={{ mt: 5, pt: 2.5, display: 'flex', justifyContent: 'space-between', gap: 2, flexWrap: 'wrap', borderTop: '1px solid rgba(222,241,238,.08)', color: 'text.secondary' }}>
        <Typography variant="caption">© IS Tour · Информационная система туристического представительства</Typography>
        <Typography variant="caption">Внутренняя система для сотрудников туристического представительства</Typography>
      </Box>
    </Container>
  </Box>
);

export default Landing;
