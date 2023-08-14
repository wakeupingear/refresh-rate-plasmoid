import QtQuick 2.0
import QtQuick.Layouts 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0

Item {
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    SystemPalette { id: myPalette; colorGroup: SystemPalette.Active }
    property color system_text_color: myPalette.highlight

    property var rates: []
    property var labels: []
    property var currentRate: -1
    property var resolution: ""
    function refresh() {
        executable.exec("xrandr | grep '*'", function(stdout) {
            lines = []
            rates = []
            var lines = stdout.split(/(\s+)/).filter( function(e) { return e.trim().length > 0; });
            resolution = lines[0]
            for (var i = 1; i < lines.length; i++) {
                var str = ""+lines[i]
                if (str.includes("*")) {
                    currentRate = i - 1
                }
                var num = str.replace(/[^0-9\.]+/g,"")
                if (num) rates.push(num)
            }

            rates.sort(function(a, b){return b-a})
            for (var i = 0; i < rates.length; i++) {
                labels.push(Math.round(Number(rates[i])) + " Hz")
            }
            for (var i=labels.length+1; i>0; i--) {
                if (labels[i] == labels[i-1]) {
                    labels.splice(i, 1);
                    rates.splice(i, 1);
                }
            }
        })
    }

    Component.onCompleted: refresh()

    Plasmoid.fullRepresentation: Column {
        Repeater {
            model: rates
            delegate: PlasmaComponents.Label {
                text: labels[index]
                Layout.alignment: Qt.AlignHCenter
                color: index == currentRate ? system_text_color : "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var cmd = "xrandr --output eDP --mode " + resolution + " --rate " + rates[index]
                        executable.exec(cmd)
                        currentRate = index
                    }
                    hoverEnabled: true
                    onEntered: {
                        parent.color = system_text_color
                    }
                    onExited: {
                        parent.color = index == currentRate ? system_text_color : "white"
                    }
                }
            }
        }
    }

    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        onNewData: {
            var stdout = data["stdout"]
            
            if (callbacks[sourceName] !== undefined) {
                callbacks[sourceName](stdout);
            }
            
            exited(sourceName, stdout)
            disconnectSource(sourceName) // cmd finished
        }
        
        function exec(cmd, onNewDataCallback) {
            if (onNewDataCallback !== undefined){
                callbacks[cmd] = onNewDataCallback
            }
            connectSource(cmd)
                    
        }
        signal exited(string sourceName, string stdout)

    }
}
