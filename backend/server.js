require('dotenv').config();

const express = require('express');
const app = express();
const httpServer = require('http').createServer(app);
const cors = require('cors');
const mongoose = require('mongoose');
const { DateTime } = require("luxon");

const uri = process.env.MONGO_URI;

app.use(cors());
app.use(express.json({ extended: false }));
app.use(express.static('public'));

mongoose.connect(uri);

const Habito = mongoose.model('Habito', {
  nome: { type: String, required: true },
  seg: { type: Boolean, required: true, default: false },
  ter: { type: Boolean, required: true, default: false },
  qua: { type: Boolean, required: true, default: false },
  qui: { type: Boolean, required: true, default: false },
  sex: { type: Boolean, required: true, default: false },
  sab: { type: Boolean, required: true, default: false },
  dom: { type: Boolean, required: true, default: false },
  dataCriacao: { type: Date, default: Date.now } 
});

const HabitoConcluido = mongoose.model('HabitoConcluido', {
  nome: { type: String },
  habitoId: { type: mongoose.Schema.Types.ObjectId, ref: 'Habito', required: true },
  dataConclusao: { type: Date, default: Date.now }
});

app.get('/', (req, res) => res.sendFile(__dirname + '/public/index.html'));

app.get('/habito', async (req, res) => {
  try {
    const habitos = await Habito.find();
    return res.status(200).json(habitos);
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.get('/habito/id/:id', async (req, res) => {
  try {
    const habito = await Habito.findById(req.params.id);
    return res.status(200).json(habito);
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.get('/habito/hoje', async (req, res) => {
  try {
    const diaSemana = DateTime.now().weekday - 1;
    const dias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sab', 'dom'];
    const filtro = {};
    filtro[dias[diaSemana]] = true;
    const habitos = await Habito.find(filtro);
    return res.status(200).json(habitos);
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.get('/habito/diaDaSemana/:diaSemana', async (req, res) => {
  try {
    const dias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sab', 'dom'];
    const filtro = {};
    filtro[dias[Number(req.params.diaSemana)]] = true;
    const habitos = await Habito.find(filtro);
    return res.status(200).json(habitos);
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.post('/habito', async function(req, res){
	try{
		const body = req.body;
		console.log(body);
		const habito = new Habito(body);
		await habito.save();
		return res.status(200).json({ success: true, id: habito._id }); // <-- aqui
	}catch(e){
		return res.status(500).json(e);
	}
});


app.put('/habito', async function(req, res){
  try{
    const body = req.body;
   
    const { id, ...updateData } = body;

    if (!id) {
       
        return res.status(400).json({ error: "ID do hábito é obrigatório para edição." });
    }

    const updatedHabito = await Habito.findByIdAndUpdate(id, updateData, { new: true });

    if(!updatedHabito){
      return res.status(404).json({ error: "Hábito não encontrado" });
    }

    return res.status(200).json({ success: true });
  }catch(e){

    console.error("Erro ao editar hábito:", e);
   
    return res.status(500).json({ error: "Erro interno do servidor ao editar hábito", details: e.message || e });
  }
});

app.delete('/habito/id/:id', async (req, res) => {
  try {
    await Habito.findByIdAndDelete(req.params.id);
    return res.status(200).json({ success: true });
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.get('/concluido', async (req, res) => {
  try {
    const concluidos = await HabitoConcluido.find();
    return res.status(200).json(concluidos);
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.get('/concluido/:ano/:mes/:dia?', async (req, res) => {
  try {
    const { ano, mes, dia } = req.params;
    const inicio = DateTime.fromObject({ year: +ano, month: +mes, day: dia ? +dia : 1 })
      .startOf(dia ? "day" : "month").toJSDate();
    const fim = DateTime.fromObject({ year: +ano, month: +mes, day: dia ? +dia : 1 })
      .endOf(dia ? "day" : "month").toJSDate();
    const concluidos = await HabitoConcluido.find({
      dataConclusao: { $gte: inicio, $lt: fim },
    });
    return res.status(200).json(concluidos);
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.get('/concluido/hoje', async (req, res) => {
  try {
    const inicio = DateTime.now().startOf("day").toJSDate();
    const fim = DateTime.now().endOf("day").toJSDate();
    const concluidos = await HabitoConcluido.find({
      dataConclusao: { $gte: inicio, $lt: fim },
    });
    return res.status(200).json(concluidos);
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.get('/concluido/nestaSemana', async (req, res) => {
  try {
    const inicio = DateTime.now().startOf("week").toJSDate();
    const fim = DateTime.now().endOf("week").toJSDate();
    const concluidos = await HabitoConcluido.find({
      dataConclusao: { $gte: inicio, $lt: fim },
    });
    return res.status(200).json(concluidos);
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.get('/concluido/nesteMes', async (req, res) => {
  try {
    const inicio = DateTime.now().startOf("month").toJSDate();
    const fim = DateTime.now().endOf("month").toJSDate();
    const concluidos = await HabitoConcluido.find({
      dataConclusao: { $gte: inicio, $lt: fim },
    });
    return res.status(200).json(concluidos);
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.get('/concluido/nesteAno', async (req, res) => {
  try {
    const inicio = DateTime.now().startOf("year").toJSDate();
    const fim = DateTime.now().endOf("year").toJSDate();
    const concluidos = await HabitoConcluido.find({
      dataConclusao: { $gte: inicio, $lt: fim },
    });
    return res.status(200).json(concluidos);
  } catch (e) {
    return res.status(500).json(e);
  }
});
app.post('/concluido', async function(req, res){
  try{
    const body = req.body;
    const habitoConcluido = new HabitoConcluido(body);
    const habito = await Habito.findOne({_id: habitoConcluido.habitoId});
    habitoConcluido.dataConclusao = new Date();
    habitoConcluido.nome = habito.nome;
    await habitoConcluido.save();
    return res.status(200).json({ success: true }); 
  }catch(e){
    return res.status(500).json(e);
  }
});



app.put('/concluido', async (req, res) => {
  try {
    const { id, dataConclusao } = req.body;
    const atualizado = await HabitoConcluido.findByIdAndUpdate(id, { dataConclusao }, { new: true });
    if (!atualizado) throw "Habito Concluído não encontrado";
    return res.status(200).json({ success: true });
  } catch (e) {
    return res.status(500).json(e);
  }
});

app.delete('/concluido/:id', async (req, res) => {
  try {
    await HabitoConcluido.findByIdAndDelete(req.params.id);
    return res.status(200).json({ success: true });
  } catch (e) {
    return res.status(404).json(e);
  }
});

httpServer.listen(8080, () => console.log("Servidor HTTP no ar!"));
