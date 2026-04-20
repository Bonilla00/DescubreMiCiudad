function calcularDistancia(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) *
    Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

function calcularTiempos(distanciaKm) {
  const velocidadCarro = 30; // km/h ciudad
  const velocidadCaminando = 5; // km/h

  const minutosCarro = Math.round(
    (distanciaKm / velocidadCarro) * 60);
  const minutosCaminando = Math.round(
    (distanciaKm / velocidadCaminando) * 60);

  return {
    distancia_km: distanciaKm,
    distancia_texto: distanciaKm < 1
      ? `${Math.round(distanciaKm * 1000)} m`
      : `${distanciaKm.toFixed(1)} km`,
    carro: minutosCarro <= 60
      ? `${minutosCarro} min`
      : `${Math.floor(minutosCarro/60)}h ${minutosCarro%60}m`,
    caminando: minutosCaminando <= 60
      ? `${minutosCaminando} min`
      : `${Math.floor(minutosCaminando/60)}h ${minutosCaminando%60}m`,
  };
}

module.exports = { calcularDistancia, calcularTiempos };
