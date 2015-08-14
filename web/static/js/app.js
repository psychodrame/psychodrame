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
    this.initRelativeTimes();
    this.loadMarkdownEditors();
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

  static loadMarkdownEditors() {
    $('.markdown-editor').each(function(index, element) {
      var autosave = { enabled: false };
      var statusbar = ['lines', 'words', 'cursor'];
      var ref = $(element).attr('data-editor-id');
      if (ref) {
        var autosave = { enabled: true, unique_id: ref, delay: 5000};
        statusbar.unshift('autosave');
      }

      editor = new SimpleMDE({
        element: element,
        spellChecker: false,
        indentWithTabs: false,
        autosave: autosave,
        status: false,
        //status: statusbar
      })

      editor.render()
    })
  }

}

$( () => App.init() )

export default App
