library(shiny)
library(shinydashboard)
library(data.table)

# Load n-gram tables and table for left-over propability
trigram.wf <- fread("input/trigram-wf.csv")
trigram.beta <- fread("input/trigram-beta.csv")
bigram.wf <- fread("input/bigram-wf.csv")
bigram.beta <- fread("input/bigram-beta.csv")
unigram.wf <- fread("input/unigram-wf.csv")

# preprocessing user input string
cleanInput <- function(input, maxN = 2) {
      input <- tolower(input)
      input <- gsub("[^[:alnum:][:space:]',.?!:-]", "", input)
      input <- gsub("\\.", " \\. ", input)
      input <- gsub("\\,", " \\, ", input)
      input <- gsub("\\!", " \\! ", input)
      input <- gsub("\\?", " \\? ", input)
      input <- gsub("\\:", " \\: ", input)
      input <- gsub("^[[:space:]]+|[[:space:]]+$", "", input)
      input <- gsub("[[:space:]]+", " ", input)
      # tokenize
      words <- unlist(strsplit(input, split = " "))
      # output bigram if sufficient words
      # otherwise unigram
      if(length(words) < maxN) {
            isTrigram = FALSE 
            input <- sapply(input, function(wd) unigram.wf[words==wd, index])
            return(list(input, isTrigram))
      }else{
            isTrigram = TRUE
            bgn <- length(words)-maxN+1
            end <- length(words)
            tmpwords <- words[bgn:end]
            tmpwords <- sapply(tmpwords, function(wd) unigram.wf[words==wd, index])
            return(list(tmpwords, isTrigram))
      }
}

probTrigramPredictor <- function(input, predict) {
#
# with bigram input plus a predict word, output the probability
# estimator from Katz back-off method (together with Good-Turing discounting)
#
# e.g. Input: want to
#      predict: sleep
#      output: 0.04536
#      
      trigram.in <- trigram.wf[ind1==input[1] & ind2==input[2]]
      if(nrow(trigram.in) > 0) {
            trigram.record <- trigram.in[ind3 == predict]
            if(nrow(trigram.record) > 0) {
                  # trigram found in model
                  freq.tot <- sum(trigram.in$freq)
                  freq.eff <- trigram.record$freq * trigram.record$discount
                  prob.final <- freq.eff / freq.tot
            } else {
                  # trigram not found -> check bigram
                  # get the leftover probability 'beta'
                  beta <- trigram.beta[ind1==input[1] & ind2==input[2]]$probLeftover
                  bigram.in <- bigram.wf[ind1 == input[2]]
                  bigram.record <- bigram.in[ind2 == predict]
                  if(nrow(bigram.record) >0 ) {
                        # bigram found in model
                        # considered only when lastword not found in trigram
                        bigram.in.remain <- bigram.in[!(bigram.in$ind2 %in% trigram.in$ind3),]
                        freq.tot <- sum(bigram.in$freq)
                        freq.eff <- sum(bigram.in.remain$freq*bigram.in.remain$discount)
                        alpha <- beta / (freq.eff / freq.tot)
                        freq.eff.record <- bigram.record$freq * bigram.record$discount
                        prob.final <- alpha * (freq.eff.record / freq.tot)
                  } else {
                        # only hope in unigram !
                        unigram.in <- unigram.wf
                        unigram.record <- unigram.wf[index == predict]
                        if(nrow(unigram.record) > 0 ) {
                              # found in unigram
                              unigram.in.remain <- unigram.in[!(unigram.in$index %in% trigram.in$ind3),]
                              freq.tot <- sum(unigram.in$freq)
                              freq.eff <- sum(unigram.in.remain$freq*unigram.in.remain$discount)
                              alpha <- beta / (freq.eff / freq.tot)
                              freq.eff.record <- unigram.record$freq * unigram.record$discount
                              prob.final <- alpha * (freq.eff.record / freq.tot)
                        } else {
                              stop(sprintf("predictor [%s] not found in trigram model", predict))
                        }
                  }
            }
            # return final probability
            prob.final
      } else {
            sprintf("input [%s] not found in trigram model.", input)
            probBigramPredictor(input[2], predict)
      }
}

probBigramPredictor <- function(input, predict) {
#      
# single word input plus a predict word, output the probability
# katz back-off with good-turing discounting
#      
      bigram.in <- bigram.wf[ind1 == input]
      if(nrow(bigram.in) > 0) {
            bigram.record <- bigram.in[ind2 == predict]
            if(nrow(bigram.record) > 0) {
                  # find bigram record
                  freq.tot <- sum(bigram.in$freq)
                  freq.eff <- bigram.record$freq * bigram.record$discount
                  prob.final <- freq.eff / freq.tot
            } else {
                  # not find bigram record, go to unigram
                  beta <- bigram.beta[ind1 == input, probLeftover]
                  unigram.in <- unigram.wf
                  unigram.record <- unigram.wf[index == predict]
                  if(nrow(unigram.record) > 0) {
                        # found in unigram
                        unigram.in.remain <- unigram.in[!(unigram.in$index %in% bigram.in$ind2),]
                        freq.tot <- sum(unigram.in$freq)
                        freq.eff <- sum(unigram.in.remain$freq * unigram.in.remain$discount)
                        alpha <- beta / (freq.eff / freq.tot)
                        freq.eff.record <- unigram.record$freq * unigram.record$discount
                        prob.final <- alpha * (freq.eff.record / freq.tot)
                  } else {
                        stop(sprintf("predictor [%s] not found in bigram model", predict))
                  }
            }
            prob.final
      } else {
            sprintf("input [%s] not found in bigram model.", input)
            probUnigramPredictor(predict)
      }
}

probUnigramPredictor <- function(predict) {
#      
# output probability of given predict word with unigram data
#
      unigram.in <- unigram.wf
      unigram.record <- unigram.wf[index == predict]
      if(nrow(unigram.record) > 0) {
            freq.tot <- sum(unigram.in$freq)
            freq.eff <- unigram.record$freq * unigram.record$discount
            prob.final <- freq.eff / freq.tot
      } else {
            # any predicted word should be found in the training corpus
            # otherwise no way to predict
            stop(sprintf("predictor [%s] not found in unigram model", predict))
      }
      prob.final
}

# simple version of prediction function
# individual words are replaced by numerical indices
katzWordPrediction <- function(rawinput) {
      predict.vector <- 1:3
      input.list <- cleanInput(rawinput)
      input <- input.list[[1]]
      isTrigram <- input.list[[2]]
      if(isTrigram == TRUE) {
            # pre-selection of 20 words as candidate predict word
            # bare Good-Turing discounted probabilities are used
            bigram.in <- bigram.wf[ind1 == input[2]]
            if(nrow(bigram.in)>0) {
                  bigram.in <- bigram.in[order(-freq*discount)]
                  predict.bigram <- bigram.in[1:min(5,nrow(bigram.in))]$ind2
                  predict.vector <- union(predict.vector, predict.bigram)
            }
            trigram.in <- trigram.wf[ind1==input[1] & ind2==input[2]]
            if(nrow(trigram.in)>0) {
                  trigram.in <- trigram.in[order(-freq*discount)]
                  predict.trigram <- trigram.in[1:min(5,nrow(trigram.in))]$ind3
                  predict.vector <- union(predict.vector, predict.trigram)
            }
            prob.vec <- sapply(predict.vector, function(x) probTrigramPredictor(input, x))
      } else {
            bigram.in <- bigram.wf[ind1 == input]
            if(nrow(bigram.in)>0) {
                  bigram.in <- bigram.in[order(-freq*discount)]
                  predict.bigram <- bigram.in[1:min(10,nrow(bigram.in))]$ind2
                  predict.vector <- union(predict.vector, predict.bigram)
            }
            prob.vec <- sapply(predict.vector, function(x) probBigramPredictor(input, x))
      }
      predict.words <- sapply(predict.vector, function(ind) unigram.wf[index==ind, words])
      # return a data table of word and probabilities
      data.table(predictor = predict.words, probability = prob.vec)
}

naiveWordPrediction <- function(rawinput) {
      input.list <- cleanInput(rawinput)
      input <- input.list[[1]]
      isTrigram <- input.list[[2]]
      if(isTrigram == TRUE) {
            trigram.in <- trigram.wf[ind1==input[1] & ind2==input[2]]
            if(nrow(trigram.in)>0) {
                  trigram.in <- trigram.in[order(-freq*discount)]
                  pred.vec <- trigram.in[1:min(13,nrow(trigram.in))]$ind3
                  freq.tot <- sum(trigram.wf$freq)
                  prob.vec <- sapply(pred.vec, function(x) trigram.in[ind3==x]$freq/freq.tot)
            }
            Nw <- length(pred.vec)
            if(Nw<13) {
                  bigram.in <- bigram.wf[ind1==input[2] & !(ind2 %in% pred.vec)]
                  if(nrow(bigram.in)>0) {
                        bigram.in <- bigram.in[order(-freq*discount)]
                        pred.bigram <- bigram.in[1:min(13-Nw,nrow(bigram.in))]$ind2
                        freq.tot <- sum(bigram.wf$freq)
                        prob.bigram <- sapply(pred.bigram, function(x) bigram.in[ind2==x]$freq/freq.tot)
                  }
                  pred.vec <- c(pred.vec, pred.bigram)
                  prob.vec <- c(prob.vec, prob.bigram)
            }
            Nw <- length(pred.vec)
            if(Nw<13) {
                  unigram.in <- unigram.wf[!(index %in% pred.vec)]
                  unigram.in <- unigram.in[order(-freq*discount)]
                  pred.unigram <- unigram.in[1:(13-Nw), index]
                  freq.tot <- sum(unigram.wf$freq)
                  prob.unigram <- sapply(pred.unigram, function(x) unigram.in[index==x]$freq/freq.tot)
                  pred.vec <- c(pred.vec, pred.unigram)
                  prob.vec <- c(prob.vec, prob.unigram)
            }
      } else {
            bigram.in <- bigram.wf[ind1==input]
            if(nrow(bigram.in)>0) {
                  bigram.in <- bigram.in[order(-freq*discount)]
                  pred.vec <- bigram.in[1:min(13,nrow(bigram.in))]$ind2
                  freq.tot <- sum(bigram.wf$freq)
                  prob.vec <- sapply(pred.vec, function(x) bigram.in[ind2==x]$freq/freq.tot)
            }
            Nw <- length(pred.vec)
            if(Nw<13) {
                  unigram.in <- unigram.wf[!(index %in% pred.vec)]
                  unigram.in <- unigram.in[order(-freq*discount)]
                  pred.unigram <- unigram.in[1:(13-Nw), index]
                  freq.tot <- sum(unigram.wf$freq)
                  prob.unigram <- sapply(pred.unigram, function(x) unigram.in[index==x]$freq/freq.tot)
                  pred.vec <- c(pred.vec, pred.unigram)
                  prob.vec <- c(prob.vec, prob.unigram)
            }
      }
      pred.wrd <- sapply(pred.vec, function(ind) unigram.wf[index==ind, words])
      data.table(predictor = pred.wrd, probability = prob.vec)
}

shinyServer(function(input, output) {

      # data table of prediction
      predDT <- reactive({
            rawinput <- input$text
            katz <- input$preference == "Katz backoff"
            if(katz) {
                  katzWordPrediction(rawinput)
            } else {
                  naiveWordPrediction(rawinput)
            }
      })

      # list of predict words
      predList <- reactive({
            maxN <- input$maxResults
            katz <- input$preference == "Katz backoff"
            if(katz) setorder(predDT(), -probability)
            as.vector(predDT()[1:maxN, predictor])
      })
      
      output$prediction <- renderPrint({
            if( input$text == "" ) {
                  print("Please begin typing...")
            } else {
                writeLines(predList(), sep = "\t")
            }
      })
      
      output$pw_plot <- renderPlot({
            par(las=2, mar=c(5, 2, 1, 10))
            bp <- barplot(predDT()$probability, horiz = TRUE, col = "#FF773D", border = NA, space = .4, width=1.5)
            text(x=predDT()$probability, y=bp, xpd=NA, pos=4, labels = predDT()$predictor, cex = 1.2)
            text(x=predDT()$probability, y=bp, xpd=NA, pos=2, labels = predDT()$probability, cex=0.75, col = "white")
      })
})