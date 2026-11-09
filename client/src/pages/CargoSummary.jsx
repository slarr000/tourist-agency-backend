import { useState, useEffect } from 'react'

function CargoSummary() {
    const [data, setData] = useState([]);

    useEffect(() => {
        fetch('http://localhost:5000/api/Reports/cargo-summary')
            .then(response => response.json())
            .then(result => setData(result))
            .catch(error => console.error('Ошибка:', error));
    }, []);

    return (
        <div>
            <h2>9. Статистика грузооборота</h2>
            <table border="1" cellPadding="10" style={{ width: '100%' }}>
                <thead>
                    <tr>
                        <th>Номер рейса</th>
                        <th>Всего мест груза</th>
                        <th>Общий вес (кг)</th>
                        <th>Общая стоимость страховки (руб)</th>
                    </tr>
                </thead>
                <tbody>
                    {data.map((item, index) => (
                        <tr key={index}>
                            <td>{item.flightNumber}</td>
                            <td>{item.totalPlaces}</td>
                            <td>{item.totalActualWeight}</td>
                            <td>{item.totalInsuranceCost}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    )
}

export default CargoSummary;