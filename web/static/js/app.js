import {Socket} from "phoenix"

// let socket = new Socket("/ws")
// socket.connect()
// let chan = socket.chan("topic:subtopic", {})
// chan.join().receive("ok", chan => {
//   console.log("Success!")
// })

class App {

  static init(){
    moment.locale(window.lng);
    this.initRelativeTimes()
  }

  static initRelativeTimes() {
    this.updateRelativeTimes()
    this.intervalRelativeTime = setInterval(this.updateRelativeTimes, 60000)
  }

  static updateRelativeTimes(){
    $('time').each(function(i, e) {
      var time = moment($(e).attr('datetime'));
      var tz = time.tz('Europe/Paris');
      $(e).html(time.fromNow());
      $(e).attr('title', time.format("LLLL"));
    })
  }

}

$( () => App.init() )

export default App
