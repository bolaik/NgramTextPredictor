### How the Algorithm Works?
The spirit of N-gram word predictions is based on the Markov assumption of individual words within a phrase, that is individual words are correlated only to their neighbouring words within finite distance (usually less than 5). The strength of word-word correlations can be predicted from a simple frequency table that is built with the bag-of-words method. More specifically, we first construct frequency tables of certain N-grams (for N=1,2,3). A N-gram is simply a N word phrase that is cut from the original sentences. When making predictions, we compare the last N-1 words in the input phrase with individual entries in the N-gram frequency table. The output word is determined by the corresponding N-grams with highest probabilities.

#### Issue with unknown N-grams
Due to the limitation of the vocabulary size we used to train our prediction model, there may exist common N-grams that are missing in our N-gram table. 

__Naive backoff__ means when we come into this situation, we simply reduce the order of the N-gram by 1 and search from the (N-1)-gram table for candidate words. This method can give us efficient estimation of the predicted words. However, it completely ignored the information of the Nth input word, thus might not be that accurate when making prediction.

__Katz backoff__ is usually used in combination with the __Good-Turing smoothing__ technique. The intuition of Good-Turing smoothing is to use the count of singletons to help estimate the count of ngrams that never appeared. The Good-Turing discount $d_c$ is defined as the ratio of the smoothed count with respect to its original count $d_c=c^*/c$. The left-over probability (or missing mass) for unseen events now is given by $P^*_{GT}(N_0)=N_1/N$. Among those unseen events, the probability mass are assumed to be evenly distributed. As one step further, Katz back-off suggests a better way of distributing the probability mass among unseen events, by relying on information of lower-order ngrams. The details of the method is shown in Ref. [1,3].

### How Well the Model Performs?

<html>
<head>
<style>
table {
    font-family: arial, sans-serif;
    font-size: 12px;
    border-collapse: collapse;
    width: 50%;
}

td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}

tr:nth-child(even) {
    background-color: #dddddd;
}
</style>
</head>
<body>

<table>
  <tr>
    <th>model</th>
    <th>top1_precision (%)</th>
    <th>top3_precision (%)</th>
    <th>avg_runtime (msec)</th>
    <th>tot_memory (mb)</th>
  </tr>
  <tr>
    <td>Katz backoff</td>
    <td>10.81</td>
    <td>15.06</td>
    <td>700.91</td>
    <td>213.76</td>
  </tr>
</table>

</body>
</html>

### Reference

- Github page of fentontaylor _Data Science Capstone_ <https://github.com/fentontaylor/DataScienceCapstone>.

- Thach-Ngoc TRAN _Katz’s Backoff Model Implementation in R_ <https://thachtranerc.wordpress.com/2016/04/12/katzs-backoff-model-implementation-in-r/>.

- Jurafsky, D. & Martin, J.H. (2000). _Speech and language processing: An introduction to natural language processing, computational linguistics and speech recognition_. Englewood Cliffs, NJ: Prentice Hall.

- Gendron G R. _Natural Language Processing: A Model to Predict a Sequence of Words_. MODSIM World 2015, 2015, 2015 (13): 1-10.

[1]: https://github.com/fentontaylor/DataScienceCapstone "Data Science Capstone"
[2]: https://thachtranerc.wordpress.com/2016/04/12/katzs-backoff-model-implementation-in-r/ "Katz’s Backoff Model Implementation in R"

