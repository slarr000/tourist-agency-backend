import { useState } from 'react'

function ExcursionTouristsCount() {
    const [report, setReport] = useState(null);
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');

    const fetchData = () => {
        if (!startDate || !endDate) {
            alert("Пожалуйста, выберите обе даты");
            return;
        }

        const params = new URLSearchParams({ startDate, endDate });

        fetch(`http://localhost:5000/api/Reports/excursions-tourists-count?${params.toString()}`)
            .then(response => response.json())
            .then(result => setReport(result))
            .catch(error => console.error('Ошибка:', error));
    };

    return (
        <div>
            <h2>6. Количество туристов на экскурсиях за период</h2>

            <div style={{ marginBottom: '20px', display: 'flex', gap: '10px' }}>
                <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} />
                <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} />
                <button onClick={fetchData}>Рассчитать</button>
            </div>

            {report && (
                <div style={{ padding: '20px', backgroundColor: '#2d2d2d', borderRadius: '5px' }}>
                    <h3>Результат:</h3>
                    <p><strong>Всего туристов посетило экскурсии:</strong> {report.totalTourists}</p>
                    <p><strong>Период:</strong> с {new Date(report.startDate).toLocaleDateString()} по {new Date(report.endDate).toLocaleDateString()}</p>
                </div>
            )}
        </div>
    )
}

export default ExcursionTouristsCount;