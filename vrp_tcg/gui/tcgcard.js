var repositories = []
var cards = {}

function addTCGRepository(url)
{
  repositories.push(url);
}

// cbreturn card structure or null
function loadTCGCard(idname, cbr)
{
  var card = cards[idname];
  if(card)
    cbr(card);
  else{
    var rep = -1;

    var step = function(){
      rep++;
      if(rep < repositories.length){ //end of search, no results
        //request card data
        $.ajax({
          dataType: "json",
          url: repositories[rep]+"cards/"+idname+".json",
          success: function(data){ //success, card loaded
            data.repository = repositories[rep];
            cards[idname] = data;
            cbr(data);
          },
          error: function(){ //error, search in another repository
            step();
          }
        });
      }
      else
        cbr(null);
    }

    step();
  }
}

defineDynamicClass("tcgcard", function(el){
  loadTCGCard(el.dataset.name, function(card){
    el.innerHTML = el.dataset.name;
    if(card){
      el.innerHTML = card.name+"<br /><img src=\""+card.repository+"images/cards/"+card.picture+"\" />";
      if(el.dataset.shiny)
        el.innerHTMl += " (shiny)";
    }
  });
});

defineDynamicClass("tcgcard_name", function(el){
  loadTCGCard(el.dataset.name, function(card){
    el.innerHTML = el.dataset.name;
    if(card){
      el.innerHTML = card.name;
    }
  });
});
