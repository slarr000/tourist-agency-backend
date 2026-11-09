import { useState, useEffect } from 'react';
import {
    Box, Typography, Paper, Table, TableBody, TableCell,
    TableContainer, TableHead, TableRow, Button, CircularProgress, Chip
} from '@mui/material';
import KingBedIcon from '@mui/icons-material/KingBed';
import DownloadIcon from '@mui/icons-material/Download';

function HotelCheckIn() {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        setTimeout(() => {
            setData([
                { id: 1, tourist: 'Иванов Иван', hotel: 'Rixos Premium', roomType: 'Suite', checkIn: '2026-11-10', nights: 7 },
                { id: 2, tourist: 'Петрова Анна', hotel: 'Marriott', roomType: 'Standard', checkIn: '2026-11-12', nights: 14 },
                { id: 3, tourist: 'Дыгданов Ярослав', hotel: 'Hilton', roomType: 'Lux', checkIn: '2026-11-15', nights: 10 },
            ]);
            setLoading(false);
        }, 800);
    }, []);

    // Функция для выбора цвета бейджа в зависимости от типа номера
    const getRoomChip = (type) => {
        switch (type) {
            case 'Lux': return <Chip label="Люкс" size="small" sx={{ backgroundColor: 'rgba(156, 39, 176, 0.1)', color: '#ce93d8', border: '1px solid rgba(156, 39, 176, 0.3)', fontWeight: 700, borderRadius: '6px' }} />;
            case 'Suite': return <Chip label="Сьют" size="small" sx={{ backgroundColor: 'rgba(255, 152, 0, 0.1)', color: '#ffb74d', border: '1px solid rgba(255, 152, 0, 0.3)', fontWeight: 700, borderRadius: '6px' }} />;
            default: return <Chip label="Стандарт" size="small" sx={{ backgroundColor: 'rgba(255, 255, 255, 0.05)', color: '#aaa', border: '1px solid rgba(255, 255, 255, 0.1)', fontWeight: 600, borderRadius: '6px' }} />;
        }
    };

    return (
        <Box sx={{ maxWidth: '1200px', margin: '0 auto', animation: 'fadeIn 0.5s ease-in-out' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', mb: 4 }}>
                <Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1 }}>
                        <Box sx={{ p: 1, borderRadius: '10px', backgroundColor: 'rgba(97, 218, 251, 0.1)', border: '1px solid rgba(97, 218, 251, 0.2)' }}>
                            <KingBedIcon sx={{ color: '#61dafb', fontSize: 24, display: 'block' }} />
                        </Box>
                        <Typography variant="h4" sx={{ fontWeight: 800, color: '#fff', letterSpacing: '-0.5px' }}>
                            Списки на расселение
                        </Typography>
                    </Box>
                    <Typography variant="body1" sx={{ color: '#888', ml: 7 }}>
                        График заездов и распределение номерного фонда
                    </Typography>
                </Box>
                <Button variant="outlined" startIcon={<DownloadIcon />} sx={{ color: '#61dafb', borderColor: 'rgba(97, 218, 251, 0.3)', borderRadius: '12px', textTransform: 'none', fontWeight: 600, '&:hover': { borderColor: '#61dafb', backgroundColor: 'rgba(97, 218, 251, 0.1)' } }}>
                    Экспорт PDF
                </Button>
            </Box>

            <TableContainer component={Paper} sx={{ backgroundColor: 'rgba(18, 18, 18, 0.4)', backdropFilter: 'blur(12px)', borderRadius: '16px', border: '1px solid rgba(255, 255, 255, 0.05)', boxShadow: '0 8px 32px rgba(0,0,0,0.2)' }}>
                <Table>
                    <TableHead sx={{ backgroundColor: 'rgba(255, 255, 255, 0.02)' }}>
                        <TableRow>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Турист</TableCell>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Отель</TableCell>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Тип номера</TableCell>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Дата заезда</TableCell>
                            <TableCell align="center" sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Ночей</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow><TableCell colSpan={5} align="center" sx={{ py: 10, borderBottom: 'none' }}><CircularProgress sx={{ color: '#61dafb' }} /></TableCell></TableRow>
                        ) : (
                            data.map((row) => (
                                <TableRow key={row.id} sx={{ '&:hover': { backgroundColor: 'rgba(255, 255, 255, 0.03)' }, '& td': { borderBottom: '1px solid rgba(255,255,255,0.03)', py: 2.5 } }}>
                                    <TableCell sx={{ fontWeight: 600, color: '#fff' }}>{row.tourist}</TableCell>
                                    <TableCell sx={{ color: '#aaa', fontWeight: 500 }}>{row.hotel}</TableCell>
                                    <TableCell>{getRoomChip(row.roomType)}</TableCell>
                                    <TableCell sx={{ color: '#aaa', fontFamily: 'monospace' }}>{row.checkIn}</TableCell>
                                    <TableCell align="center" sx={{ fontWeight: 600, color: '#fff' }}>{row.nights}</TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </Box>
    );
}

export default HotelCheckIn;