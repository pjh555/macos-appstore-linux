import QtQuick

Item {
    id: root

    property string name: ""
    property color color: "#ffffff"
    property real strokeWidth: 1.8
    property bool fill: false

    implicitWidth: 18
    implicitHeight: 18

    onNameChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onStrokeWidthChanged: canvas.requestPaint()
    onFillChanged: canvas.requestPaint()

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.save();
            ctx.clearRect(0, 0, width, height);
            const factor = Math.min(width, height) / 24;
            ctx.scale(factor, factor);
            ctx.strokeStyle = root.color;
            ctx.fillStyle = root.color;
            ctx.lineWidth = root.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            function line(x1, y1, x2, y2) {
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.stroke();
            }
            function poly(points, close, fillIt) {
                ctx.beginPath();
                ctx.moveTo(points[0], points[1]);
                for (let i = 2; i < points.length; i += 2)
                    ctx.lineTo(points[i], points[i + 1]);
                if (close)
                    ctx.closePath();
                if (fillIt)
                    ctx.fill();
                else
                    ctx.stroke();
            }
            function circle(cx, cy, r, fillIt) {
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2, false);
                if (fillIt)
                    ctx.fill();
                else
                    ctx.stroke();
            }
            function roundRect(x, y, w, h, r, fillIt) {
                ctx.beginPath();
                ctx.moveTo(x + r, y);
                ctx.arcTo(x + w, y, x + w, y + h, r);
                ctx.arcTo(x + w, y + h, x, y + h, r);
                ctx.arcTo(x, y + h, x, y, r);
                ctx.arcTo(x, y, x + w, y, r);
                ctx.closePath();
                if (fillIt)
                    ctx.fill();
                else
                    ctx.stroke();
            }

            switch (root.name) {
            case "chevron-left":
                poly([15, 5, 8, 12, 15, 19], false, false);
                break;
            case "chevron-right":
                poly([9, 5, 16, 12, 9, 19], false, false);
                break;
            case "chevron-up":
                poly([5, 15, 12, 8, 19, 15], false, false);
                break;
            case "chevron-down":
                poly([5, 9, 12, 16, 19, 9], false, false);
                break;
            case "arrow-up":
                line(12, 20, 12, 5);
                poly([6, 11, 12, 5, 18, 11], false, false);
                break;
            case "close":
                line(6, 6, 18, 18);
                line(18, 6, 6, 18);
                break;
            case "minimize":
                line(6, 12, 18, 12);
                break;
            case "maximize":
                line(5, 12, 19, 12);
                break;
            case "fullscreen":
                poly([14, 4, 20, 4, 20, 10], false, false);
                line(20, 4, 13, 11);
                poly([10, 20, 4, 20, 4, 14], false, false);
                line(4, 20, 11, 13);
                break;
            case "exit-fullscreen":
                poly([20, 9, 15, 9, 15, 4], false, false);
                line(15, 9, 21, 3);
                poly([4, 15, 9, 15, 9, 20], false, false);
                line(9, 15, 3, 21);
                break;
            case "sidebar":
                ctx.beginPath();
                ctx.rect(3, 4, 18, 16);
                ctx.stroke();
                ctx.save();
                ctx.globalAlpha = 0.30;
                ctx.fillRect(4.2, 5.2, 4.5, 13.6);
                ctx.restore();
                line(9, 4, 9, 20);
                break;
            case "grid":
                for (const r of [[4, 4], [13, 4], [4, 13], [13, 13]])
                    roundRect(r[0], r[1], 7, 7, 1.8, true);
                break;
            case "list":
                for (let i = 0; i < 3; ++i) {
                    const y = 6 + i * 6;
                    roundRect(4, y - 1.2, 2.4, 2.4, 0.8, true);
                    roundRect(8.5, y - 1.2, 11.5, 2.4, 1.0, true);
                }
                break;
            case "columns":
                roundRect(3, 4, 5.4, 16, 1.5, false);
                roundRect(9.3, 4, 5.4, 16, 1.5, false);
                roundRect(15.6, 4, 5.4, 16, 1.5, false);
                line(4.6, 8, 6.6, 8);
                line(10.9, 8, 12.9, 8);
                line(17.2, 8, 19.2, 8);
                break;
            case "gallery":
                roundRect(3, 4, 18, 13, 2, false);
                poly([5, 14.5, 9, 10, 12.5, 13.5, 15, 11, 19, 14.5], false, false);
                circle(17.2, 7.8, 1.2, true);
                line(5, 20, 19, 20);
                break;
            case "search":
                circle(10.5, 10.5, 5.8, false);
                line(15, 15, 20.5, 20.5);
                break;
            case "sort":
                line(4, 6.5, 20, 6.5);
                line(4, 12, 15, 12);
                line(4, 17.5, 10, 17.5);
                break;
            case "tag":
                poly([3.5, 4.5, 11.5, 4.5, 20, 13, 13, 20, 4.5, 11.5, 3.5, 4.5], true, false);
                circle(8, 8.5, 1.5, true);
                break;
            case "share":
                poly([8, 10, 5, 10, 5, 20, 19, 20, 19, 10, 16, 10], false, false);
                line(12, 15, 12, 3.5);
                poly([8, 7, 12, 3, 16, 7], false, false);
                break;
            case "gear":
                circle(12, 12, 3.1, false);
                circle(12, 12, 7.6, false);
                for (let i = 0; i < 8; ++i) {
                    const a = i * Math.PI / 4;
                    line(12 + Math.cos(a) * 7.6, 12 + Math.sin(a) * 7.6,
                         12 + Math.cos(a) * 9.8, 12 + Math.sin(a) * 9.8);
                }
                break;
            case "ellipsis":
                circle(5.5, 12, 1.5, true);
                circle(12, 12, 1.5, true);
                circle(18.5, 12, 1.5, true);
                break;
            case "plus":
                line(12, 5, 12, 19);
                line(5, 12, 19, 12);
                break;
            case "minus":
                line(5, 12, 19, 12);
                break;
            case "folder":
                poly([3, 8, 3, 18.5, 21, 18.5, 21, 7, 12, 7, 10, 4.5, 5, 4.5, 3, 6], true, false);
                break;
            case "folder-plus":
                poly([3, 8, 3, 18.5, 21, 18.5, 21, 7, 12, 7, 10, 4.5, 5, 4.5, 3, 6], true, false);
                line(12, 11, 12, 16);
                line(9.5, 13.5, 14.5, 13.5);
                break;
            case "file-plus":
                poly([6, 3, 14, 3, 19, 8, 19, 21, 6, 21, 6, 3], true, false);
                poly([14, 3, 14, 8, 19, 8], false, false);
                line(12.5, 12, 12.5, 17);
                line(10, 14.5, 15, 14.5);
                break;
            case "info":
                circle(12, 12, 8.6, false);
                circle(12, 8, 1.05, true);
                line(12, 11.5, 12, 16.5);
                break;
            case "open-with":
                roundRect(3, 5, 12, 14, 2, false);
                poly([13, 10, 21, 10, 21, 18], false, false);
                line(17, 6, 21, 10);
                line(21, 10, 17, 14);
                break;
            case "external":
                poly([13, 4, 20, 4, 20, 11], false, false);
                line(20, 4, 11, 13);
                poly([18, 14, 18, 20, 4, 20, 4, 6, 10, 6], false, false);
                break;
            case "copy":
                roundRect(8, 8, 12, 12, 1.6, false);
                poly([16, 5, 4, 5, 4, 17], false, false);
                break;
            case "cut":
                circle(7, 18, 2.5, false);
                circle(17, 18, 2.5, false);
                line(8.8, 15.8, 16, 4);
                line(15.2, 15.8, 8, 4);
                break;
            case "paste":
                roundRect(5, 5, 14, 16, 2, false);
                roundRect(9, 3, 6, 4, 1.3, false);
                line(9, 11, 15, 11);
                line(9, 15, 14, 15);
                break;
            case "rename":
                poly([4, 20, 5.5, 14.5, 16, 4, 20, 8, 9.5, 18.5, 4, 20], true, false);
                line(14.5, 5.5, 18.5, 9.5);
                break;
            case "duplicate":
                roundRect(4, 4, 11, 14, 1.6, false);
                roundRect(9, 7, 11, 14, 1.6, false);
                break;
            case "compress":
                poly([5, 4, 19, 4, 19, 9, 5, 9], true, false);
                line(5, 9, 19, 9);
                line(5, 15, 19, 15);
                poly([5, 20, 19, 20, 19, 15, 5, 15], true, false);
                line(12, 4, 12, 20);
                break;
            case "extract":
                poly([4, 10, 20, 10, 20, 20, 4, 20], true, false);
                line(12, 4, 12, 14);
                poly([8, 9, 12, 4, 16, 9], false, false);
                break;
            case "check":
                poly([4.5, 12, 9.5, 17, 19.5, 6.5], false, false);
                break;
            case "checkmark":
                poly([4.5, 12.5, 9.5, 17.5, 20, 6], false, false);
                break;
            case "trash":
                line(4, 6.5, 20, 6.5);
                poly([9, 6.5, 9, 4, 15, 4, 15, 6.5], false, false);
                poly([6, 6.5, 7, 20, 17, 20, 18, 6.5], false, false);
                line(10, 10, 10, 16.5);
                line(14, 10, 14, 16.5);
                break;
            case "trash-empty":
                line(4, 6.5, 20, 6.5);
                poly([9, 6.5, 9, 4, 15, 4, 15, 6.5], false, false);
                poly([6, 6.5, 7, 20, 17, 20, 18, 6.5], false, false);
                break;
            case "restore":
                ctx.beginPath();
                ctx.arc(12, 13, 7.5, Math.PI * 0.7, Math.PI * 2.1, false);
                ctx.stroke();
                poly([4, 6, 4.2, 11, 9, 9.8], true, true);
                break;
            case "refresh":
                ctx.beginPath();
                ctx.arc(12, 12, 7.5, Math.PI * 0.2, Math.PI * 1.65, false);
                ctx.stroke();
                poly([17.8, 9.8, 18.2, 15.2, 13, 13.4], true, true);
                break;
            case "computer":
                roundRect(3, 4, 18, 12.5, 1.6, false);
                line(8, 21, 16, 21);
                line(12, 16.5, 12, 21);
                break;
            case "drive":
                roundRect(3, 7, 18, 10, 2.4, false);
                line(3, 12, 21, 12);
                circle(17.5, 14.5, 0.9, true);
                line(6.5, 14.5, 12, 14.5);
                break;
            case "eject":
                poly([6, 14, 12, 7, 18, 14], true, false);
                line(5, 18.5, 19, 18.5);
                break;
            case "home":
                poly([3, 11.5, 12, 4, 21, 11.5], false, false);
                poly([5.5, 10, 5.5, 20, 18.5, 20, 18.5, 10], false, false);
                poly([10, 20, 10, 14, 14, 14, 14, 20], false, false);
                break;
            case "clock":
                circle(12, 12, 8.4, false);
                line(12, 7, 12, 12);
                line(12, 12, 16, 14.5);
                break;
            case "desktop":
                roundRect(3, 4, 18, 13, 1.4, false);
                line(3, 13.5, 21, 13.5);
                line(12, 17, 12, 20);
                line(7.5, 20.5, 16.5, 20.5);
                break;
            case "document":
                poly([6, 3, 13.5, 3, 18.5, 8, 18.5, 21, 6, 21, 6, 3], true, false);
                poly([13.5, 3, 13.5, 8, 18.5, 8], false, false);
                line(9, 12, 15.5, 12);
                line(9, 15, 15.5, 15);
                line(9, 18, 13, 18);
                break;
            case "download":
                circle(12, 12, 8.5, false);
                line(12, 7, 12, 14);
                poly([8.5, 11, 12, 14.5, 15.5, 11], false, false);
                line(8, 17, 16, 17);
                break;
            case "pictures":
                roundRect(3, 4.5, 18, 15, 1.6, false);
                circle(8.2, 9.2, 1.4, true);
                poly([4.5, 17.5, 9.5, 12.5, 13.2, 16.2, 15.5, 13.6, 19.5, 17.5], false, false);
                break;
            case "music":
                line(9, 18, 9, 6);
                line(9, 6, 18, 4.5);
                line(18, 4.5, 18, 16);
                circle(6.8, 18, 2.4, true);
                circle(15.8, 16, 2.4, true);
                break;
            case "video":
                roundRect(2.5, 6, 14, 12, 1.6, false);
                poly([17.5, 10, 21.5, 7.5, 21.5, 16.5, 17.5, 14], true, true);
                break;
            case "apps":
                for (const r of [[4, 4], [13.5, 4], [4, 13.5], [13.5, 13.5]])
                    roundRect(r[0], r[1], 6.5, 6.5, 1.7, true);
                break;
            case "terminal":
                roundRect(3, 4.5, 18, 15, 2, false);
                poly([7, 9, 10.5, 12, 7, 15], false, false);
                line(12, 15.5, 16.5, 15.5);
                break;
            case "lock":
                roundRect(5.5, 10.5, 13, 10, 1.7, false);
                ctx.beginPath();
                ctx.arc(12, 10.5, 3.7, Math.PI, 0, false);
                ctx.stroke();
                circle(12, 15.3, 1.2, true);
                break;
            case "warning":
                poly([12, 3.5, 21, 20, 3, 20], true, false);
                line(12, 9, 12, 14);
                circle(12, 17, 1.0, true);
                break;
            case "eye":
                ctx.beginPath();
                ctx.moveTo(3, 12);
                ctx.quadraticCurveTo(12, 3.5, 21, 12);
                ctx.quadraticCurveTo(12, 20.5, 3, 12);
                ctx.closePath();
                ctx.stroke();
                circle(12, 12, 2.9, false);
                break;
            case "eye-off":
                ctx.beginPath();
                ctx.moveTo(3, 12);
                ctx.quadraticCurveTo(12, 3.5, 21, 12);
                ctx.quadraticCurveTo(12, 20.5, 3, 12);
                ctx.closePath();
                ctx.stroke();
                circle(12, 12, 2.9, false);
                line(4, 20, 20, 4);
                break;
            case "star":
                poly([12, 3.5, 14.7, 9.2, 21, 9.9, 16.3, 14.3, 17.5, 20.5, 12, 17.4, 6.5, 20.5, 7.7, 14.3, 3, 9.9, 9.3, 9.2], true, true);
                break;
            case "dot":
                circle(12, 12, 3.5, true);
                break;
            case "mount":
                roundRect(4, 6, 16, 12, 2, false);
                line(4, 12, 20, 12);
                circle(16.5, 15.5, 1, true);
                break;
            case "sun":
                circle(12, 12, 4, false);
                for (let i = 0; i < 8; ++i) {
                    const angle = i * Math.PI / 4;
                    line(12 + Math.cos(angle) * 7, 12 + Math.sin(angle) * 7, 12 + Math.cos(angle) * 9.5, 12 + Math.sin(angle) * 9.5);
                }
                break;
            case "moon":
                ctx.beginPath();
                ctx.arc(13.2, 11.2, 6.5, Math.PI * 0.35, Math.PI * 1.55, false);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(18.5, 4.5, 5.2, 0, Math.PI * 2, false);
                ctx.fill();
                break;
            default:
                circle(12, 12, 7, false);
                break;
            }
            ctx.restore();
        }
    }

    function requestPaint() {
        canvas.requestPaint();
    }
}
