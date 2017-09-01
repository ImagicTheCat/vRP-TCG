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
            if(!data.rank) data.rank = 0;
            if(!data.quote) data.quote = "";
            if(!data.picture) data.picture = "";
            if(!data.name) data.name = "";

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

var rank_colors = [
  "rgb(0,0,0)",
  "rgb(0,234,255)",
  "rgb(244,200,0)",
  "rgb(255,52,214)",
  "rgb(0,255,115)"
]

defineDynamicClass("tcgcard", function(el){
  loadTCGCard(el.dataset.name, function(card){
    if(card){
      if(el.dataset.shiny)
        el.classList.add("shiny");

      var div_over = document.createElement("div");
      div_over.classList.add("over");
      el.appendChild(div_over);

      var div_title = document.createElement("div");
      div_title.classList.add("title");
      div_title.innerHTML = card.name;
      div_title.style.textShadow = "0px 0px 8px "+(rank_colors[card.rank] || rank_colors[0]);
      div_title.style.textShadow += "0px 0px 14px "+(rank_colors[card.rank] || rank_colors[0]);
      el.appendChild(div_title);

      var div_desc = document.createElement("div");
      div_desc.classList.add("desc");
      div_desc.innerHTML = card.quote;
      el.appendChild(div_desc);

      var div_pic = document.createElement("div");
      div_pic.classList.add("picture");
      var picture = card.repository+"images/cards/"+card.picture;
      div_pic.style.backgroundImage = "url(\""+picture+"\")";
      el.appendChild(div_pic);

      var div_rank = document.createElement("div");
      div_rank.classList.add("rank");
      div_rank.style.backgroundImage = "url(\"nui://vrp_tcg/images/rank_"+card.rank+".png\")";

      el.appendChild(div_rank);
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
