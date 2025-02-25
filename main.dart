// ignore_for_file: deprecated_member_use

import 'dart:html';
import 'dart:math' as math;

// Константы
const double WIDTH = 800;
const double HEIGHT = 600;
const double AU = 149.6e6 * 1000; // Астрономическая единица в метрах
const double G = 6.67428e-11;     // Гравитационная постоянная
const double SCALE = 85 / AU;      // Масштаб
const double TIMESTEP = 3600 * 24; // 1 день в секундах

class CelestialBody {
    double x;
    double y;
    double z;  // Добавляем z-координату
    double radius;
    String color;
    double mass;
    String name;
    late double orbitalRadius;
    List<List<double>> trail = [];
    bool isSun;
    late double angularVelocity;
    late double inclination;  // Угол наклона орбиты
    bool isHovered = false;

    CelestialBody(this.x, this.y, this.radius, this.color, this.mass, 
                 this.name, {this.isSun = false, this.inclination = 0.0}) : z = 0 {
        orbitalRadius = math.sqrt(x * x + y * y);
        if (!isSun) {
            angularVelocity = math.sqrt(G * 1.98892e30 / 
                            (orbitalRadius * orbitalRadius * orbitalRadius));
        }
    }

    // Конвертируем 3D координаты в изометрические 2D
    List<double> to2D(double x, double y, double z) {
        // Изометрические коэффициенты
        double isoX = (x - z) * math.cos(math.pi / 6);
        double isoY = y + (x + z) * math.sin(math.pi / 6);
        return [isoX, isoY];
    }

    void draw(CanvasRenderingContext2D ctx) {
        var iso = to2D(x * SCALE, y * SCALE, z * SCALE);
        double screenX = iso[0] + WIDTH / 2;
        double screenY = iso[1] + HEIGHT / 2;

        // Рисуем орбиту
        if (!isSun) {
            ctx.beginPath();
            ctx.strokeStyle = 'rgba(50, 50, 50, 0.3)';
            // Рисуем эллиптическую орбиту
            for (double angle = 0; angle < 2 * math.pi; angle += 0.1) {
                double orbitX = orbitalRadius * math.cos(angle);
                double orbitY = orbitalRadius * math.sin(angle);
                double orbitZ = orbitalRadius * math.sin(angle) * math.sin(inclination);
                
                var isoOrbit = to2D(orbitX * SCALE, orbitY * SCALE, orbitZ * SCALE);
                
                if (angle == 0) {
                    ctx.moveTo(isoOrbit[0] + WIDTH / 2, isoOrbit[1] + HEIGHT / 2);
                } else {
                    ctx.lineTo(isoOrbit[0] + WIDTH / 2, isoOrbit[1] + HEIGHT / 2);
                }
            }
            ctx.stroke();

            // Рисуем трассер
            if (trail.length > 2) {
                ctx.beginPath();
                ctx.strokeStyle = color;
                ctx.lineWidth = 1.5;
                
                for (int i = 0; i < trail.length; i++) {
                    var isoTrail = to2D(
                        trail[i][0] * SCALE, 
                        trail[i][1] * SCALE, 
                        trail[i][2] * SCALE
                    );
                    
                    if (i == 0) {
                        ctx.moveTo(isoTrail[0] + WIDTH / 2, isoTrail[1] + HEIGHT / 2);
                    } else {
                        ctx.lineTo(isoTrail[0] + WIDTH / 2, isoTrail[1] + HEIGHT / 2);
                    }
                }
                
                // Делаем трассер полупрозрачным
                ctx.globalAlpha = 0.3;
                ctx.stroke();
                ctx.globalAlpha = 1.0;
            }
        }

        // Рисуем тень под планетой
        ctx.beginPath();
        ctx.fillStyle = 'rgba(0, 0, 0, 0.3)';
        ctx.ellipse(
            screenX,
            screenY + radius * 0.7,
            radius * 0.8,
            radius * 0.3,
            0,
            0,
            2 * math.pi,
            false
        );
        ctx.fill();

        // Рисуем планету с градиентом для создания эффекта объёма
        ctx.beginPath();
        var gradient = ctx.createRadialGradient(
            screenX - radius * 0.4,  // Смещаем центр блика
            screenY - radius * 0.4,
            0,
            screenX,
            screenY,
            radius
        );

        // Настраиваем градиент в зависимости от того, Солнце это или планета
        if (isSun) {
            gradient.addColorStop(0, '#FFF7EB');
            gradient.addColorStop(0.5, '#FFE87C');
            gradient.addColorStop(1, '#FFA500');
        } else {
            gradient.addColorStop(0, 'rgba(255, 255, 255, 0.8)');  // Блик
            gradient.addColorStop(0.3, color);                      // Основной цвет
            gradient.addColorStop(1, darkenColor(color));          // Затемнение краёв
        }

        ctx.fillStyle = gradient;
        ctx.arc(screenX, screenY, radius, 0, 2 * math.pi);
        ctx.fill();

        // Добавляем блик
        ctx.beginPath();
        var highlightGradient = ctx.createRadialGradient(
            screenX - radius * 0.4,
            screenY - radius * 0.4,
            0,
            screenX - radius * 0.4,
            screenY - radius * 0.4,
            radius * 0.6
        );
        highlightGradient.addColorStop(0, 'rgba(255, 255, 255, 0.4)');
        highlightGradient.addColorStop(1, 'rgba(255, 255, 255, 0)');
        ctx.fillStyle = highlightGradient;
        ctx.arc(screenX, screenY, radius, 0, 2 * math.pi);
        ctx.fill();

        // Рисуем название
        if (!isSun) {
            ctx.fillStyle = color;
            ctx.font = '12px Arial';
            ctx.fillText(name, screenX - 15, screenY - radius - 5);
        }
        // Добавляем подсветку при наведении
        if (isHovered) {
            ctx.beginPath();
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.5)';
            ctx.lineWidth = 2;
            ctx.arc(screenX, screenY, radius + 5, 0, 2 * math.pi);
            ctx.stroke();
        }
    }

    // Вспомогательная функция для затемнения цвета
    String darkenColor(String color) {
        var r = int.parse(color.substring(1, 3), radix: 16);
        var g = int.parse(color.substring(3, 5), radix: 16);
        var b = int.parse(color.substring(5, 7), radix: 16);
        
        r = (r * 0.7).round();
        g = (g * 0.7).round();
        b = (b * 0.7).round();
        
        return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
    }

    void update() {
        if (!isSun) {
            double currentAngle = math.atan2(y, x);
            double newAngle = currentAngle + angularVelocity * TIMESTEP;

            x = orbitalRadius * math.cos(newAngle);
            y = orbitalRadius * math.sin(newAngle) * math.cos(inclination);
            z = orbitalRadius * math.sin(newAngle) * math.sin(inclination);

            // Добавляем текущую позицию в трассер
            trail.add([x, y, z]);
            // Ограничиваем длину трассера
            if (trail.length > 50) {
                trail.removeAt(0);
            }
        }
    }

    bool containsPoint(double px, double py) {
        var iso = to2D(x * SCALE, y * SCALE, z * SCALE);
        double screenX = iso[0] + WIDTH / 2;
        double screenY = iso[1] + HEIGHT / 2;
        
        double dx = px - screenX;
        double dy = py - screenY;
        return dx * dx + dy * dy <= radius * radius;
    }
}

void main() {
    CanvasElement? canvas = querySelector('#solarSystem') as CanvasElement?;
    if (canvas == null) {
        print('Canvas element not found!');
        return;
    }
    var ctx = canvas.getContext('2d') as CanvasRenderingContext2D;

    // Создаем небесные тела
    var sun = CelestialBody(0, 0, 20, '#FFE87C', 1.98892e30, 'Солнце', 
                          isSun: true);
    var planets = [
        sun,
        CelestialBody(0.387 * AU, 0, 6, '#A9A9A9', 3.30e23, 'Меркурий', inclination: 0.122173),
        CelestialBody(0.723 * AU, 0, 10, '#FFC649', 4.87e24, 'Венера', inclination: 0.059),
        CelestialBody(1.0 * AU, 0, 10, '#6495ED', 5.97e24, 'Земля', inclination: 0.041),
        CelestialBody(1.524 * AU, 0, 8, '#BC2732', 6.42e23, 'Марс', inclination: 0.032),
        CelestialBody(2.5 * AU, 0, 15, '#FF7D11', 1.90e27, 'Юпитер', inclination: 0.022),
        CelestialBody(3.0 * AU, 0, 14, '#E8E8CD', 5.68e26, 'Сатурн', inclination: 0.026),
        CelestialBody(3.5 * AU, 0, 12, '#ADD8E6', 8.68e25, 'Уран'),
        CelestialBody(4.0 * AU, 0, 12, '#000080', 1.02e26, 'Нептун')
    ];

    bool isPaused = false;
    double simulationSpeed = 1.0;

    // Добавляем обработчики событий
    var pauseButton = querySelector('#pauseButton') as ButtonElement;
    var speedSlider = querySelector('#speedSlider') as InputElement;
    var speedValue = querySelector('#speedValue') as SpanElement;

    pauseButton.onClick.listen((event) {
        isPaused = !isPaused;
        pauseButton.text = isPaused ? "Продолжить ▶️" : "Пауза ⏸️";
    });

    speedSlider.onInput.listen((event) {
        simulationSpeed = double.parse(speedSlider.value!);
        speedValue.text = '${simulationSpeed.toStringAsFixed(1)}x';
    });

    // Обработка наведения мыши
    canvas.onMouseMove.listen((event) {
        var rect = canvas.getBoundingClientRect();
        var x = (event.client.x - rect.left).toDouble();
        var y = (event.client.y - rect.top).toDouble();
        
        bool foundHover = false;
        for (var planet in planets) {
            if (planet.containsPoint(x, y)) {
                planet.isHovered = true;
                foundHover = true;
            } else {
                planet.isHovered = false;
            }
        }
        canvas.style.cursor = foundHover ? 'pointer' : 'default';
    });

    void update(num time) {
        ctx.fillStyle = '#000000';
        ctx.fillRect(0, 0, WIDTH, HEIGHT);

        if (!isPaused) {
            for (var planet in planets) {
                // Обновляем с учетом скорости симуляции
                for (var i = 0; i < simulationSpeed; i++) {
                    planet.update();
                }
            }
        }

        for (var planet in planets) {
            planet.draw(ctx);
        }

        window.requestAnimationFrame(update);
    }

    window.requestAnimationFrame(update);
}